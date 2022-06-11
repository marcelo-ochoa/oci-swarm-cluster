#!/bin/bash -x
# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#
# Description: Sets up Swarm Basic a.k.a. "Monolite".
# Return codes: 0 =
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# Configure firewall
firewall-offline-cmd --add-port=80/tcp
firewall-offline-cmd --add-port=443/tcp
# GlusterFS
firewall-offline-cmd --zone=public --add-port=24007-24008/tcp
firewall-offline-cmd --zone=public --add-port=24007-24008/udp
firewall-offline-cmd --zone=public --add-port=49152-49156/tcp
firewall-offline-cmd --zone=public --add-port=49152-49156/udp
# Docker
firewall-offline-cmd --zone=public --add-port=2377/tcp
firewall-offline-cmd --zone=public --add-port=7946/tcp
firewall-offline-cmd --zone=public --add-port=7946/udp
firewall-offline-cmd --zone=public --add-port=4789/udp
systemctl restart firewalld

dnf clean metadata -y

# Install tools
dnf -y install unzip jq

# Install Oracle Instant Client
dnf -y install oracle-release-el8
dnf config-manager --enable ol8_oracle_instantclient
dnf -y install git oracle-instantclient${oracle_client_version}-basic oracle-instantclient${oracle_client_version}-jdbc oracle-instantclient${oracle_client_version}-sqlplus

# Setup GlusterFS and Docker
dnf -y install oracle-gluster-release-el8
dnf config-manager --enable ol8_gluster_appstream ol8_baseos_latest ol8_appstream
dd if=/dev/zero of=/home/fs.img count=0 bs=1 seek=20G
mkfs.xfs -f -i size=512 -L glusterfs /home/fs.img
mkdir -p /data/glusterfs/myvolume/mybrick
echo '/home/fs.img /data/glusterfs/myvolume/mybrick xfs defaults  0 0' >> /etc/fstab
mount -a && df
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sed -i "s/\$releasever/8/g" /etc/yum.repos.d/docker-ce.repo
dnf -y install glusterfs-server docker-ce docker-ce-cli containerd.io
systemctl enable --now glusterd
systemctl enable --now docker

source /root/swarm.env
export $(cut -d= -f1 /root/swarm.env)

my_ip=$(ip a show enp0s3|grep 'inet '|cut -d' ' -f6| sed 's/\/24//')
my_base_hostname="oci-swarm-$DEPLOY_ID"

if [[ $(echo $(hostname) | grep "\-0$") ]]; then
    echo "$(host oci-swarm-$DEPLOY_ID-1|cut -d' ' -f4) oci-swarm-$DEPLOY_ID-1" >> /etc/hosts
else
    if [[ $(echo $(hostname) | grep "\-1$") ]]; then
        echo "$(host oci-swarm-$DEPLOY_ID-0|cut -d' ' -f4) oci-swarm-$DEPLOY_ID-0" >> /etc/hosts
    else
        echo "$(host oci-swarm-$DEPLOY_ID-0|cut -d' ' -f4) oci-swarm-$DEPLOY_ID-0" >> /etc/hosts
        echo "$(host oci-swarm-$DEPLOY_ID-1|cut -d' ' -f4) oci-swarm-$DEPLOY_ID-1" >> /etc/hosts
    fi
fi
echo "${private_key_pem}" > /root/.ssh/id_rsa
echo "${public_key_openssh}" > /root/.ssh/authorized_keys
chmod go-rwx /root/.ssh/*

docker plugin install --alias glusterfs mochoa/glusterfs-volume-plugin-aarch64 --grant-all-permissions --disable

if [[ $(echo $(hostname) | grep "\-0$") ]]; then
    docker swarm init --advertise-addr enp0s3
fi

docker plugin enable glusterfs
docker plugin install --alias s3fs mochoa/s3fs-volume-plugin-aarch64 --grant-all-permissions --disable

peer_ready() {
    gluster peer probe $1 > /dev/null 2>&1
}

volume_ready() {
    gluster v info myvolume > /dev/null 2>&1
}

mount_gluster_vol () {
    peer_host="$my_base_hostname-0"
    while !(peer_ready $peer_host)
    do
        sleep 3
    done
    while !(volume_ready)
    do
        sleep 3
    done
    sleep 30s
    mkdir -p /gluster-storage
    echo "localhost:/myvolume /gluster-storage glusterfs defaults,_netdev 0 0" >> /etc/fstab
    mount /gluster-storage && df -h
}

create_gluster_vol () {
    peer_host="$my_base_hostname-1"
    while !(peer_ready $peer_host)
    do
        sleep 3
    done
    sleep 10s
    gluster volume create myvolume replica 2 $my_base_hostname-{0,1}:/data/glusterfs/myvolume/mybrick/brick force
    gluster volume start myvolume
    sleep 10s
    mkdir -p /gluster-storage
    echo "localhost:/myvolume /gluster-storage glusterfs defaults,_netdev 0 0" >> /etc/fstab
    mount /gluster-storage && df -h
}

if [[ $(echo $(hostname) | grep "\-0$") ]]; then
    create_gluster_vol
else
    if [[ $(echo $(hostname) | grep "\-1$") ]]; then
        mount_gluster_vol
        sleep 30s
        eval $(ssh -o "StrictHostKeyChecking no" root@$my_base_hostname-0 docker swarm join-token manager | tail -2)
    else
        sleep 60s
        eval $(ssh -o "StrictHostKeyChecking no" root@$my_base_hostname-0 docker swarm join-token worker | tail -2)
    fi
fi

######################################
echo "Finished running setup.sh"