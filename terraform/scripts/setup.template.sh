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

# Install the yum repo
yum clean metadata
yum-config-manager --enable ol7_latest

# Install tools
yum -y erase nodejs
yum -y install unzip jq

# Install Oracle Instant Client
yum -y install oracle-release-el7
yum-config-manager --enable ol7_oracle_instantclient
yum -y install oracle-instantclient${oracle_client_version}-basic oracle-instantclient${oracle_client_version}-jdbc oracle-instantclient${oracle_client_version}-sqlplus

# Setup GlusterFS and Docker
yum install -y oracle-gluster-release-el7
yum-config-manager --enable ol7_gluster5 ol7_addons ol7_latest ol7_optional_latest ol7_UEKR5
dd if=/dev/zero of=/home/fs.img count=0 bs=1 seek=20G
mkfs.xfs -f -i size=512 -L glusterfs /home/fs.img
mkdir -p /data/glusterfs/myvolume/mybrick
echo '/home/fs.img /data/glusterfs/myvolume/mybrick xfs defaults  0 0' >> /etc/fstab
mount -a && df
yum install -y glusterfs-server docker-engine
systemctl enable --now glusterd
systemctl enable --now docker

my_ip=$(ip a show ens3|grep inet|cut -d' ' -f6| sed 's/\/24//')
echo "$my_ip  $(hostname)" >> /etc/hosts
if [[ $(echo $(hostname) | grep "\-0$") ]]; then
    if [[ "$my_ip" == 10.1.21.2 ]]; then
        echo "10.1.21.3  $(echo $(hostname) | sed s/\-0/\-1/)" >> /etc/hosts
    else
        echo "10.1.21.2  $(echo $(hostname) | sed s/\-0/\-1/)" >> /etc/hosts
    fi
else
    if [[ "$my_ip" == 10.1.21.3 ]]; then
        echo "10.1.21.2  $(echo $(hostname) | sed s/\-1/\-0/)" >> /etc/hosts
    else
        echo "10.1.21.3  $(echo $(hostname) | sed s/\-1/\-0/)" >> /etc/hosts
    fi
fi
echo "${private_key_pem}" > /root/.ssh/id_rsa
echo "${public_key_openssh}" > /root/.ssh/authorized_keys
chmod go-rwx /root/.ssh/*

docker plugin install --alias glusterfs mochoa/glusterfs-volume-plugin --grant-all-permissions --disable

if [[ $(echo $(hostname) | grep "\-0$") ]]; then
    docker swarm init --advertise-addr ens3
    docker plugin set glusterfs SERVERS=localhost,$(echo $(hostname) | sed s/\-0/\-1/)
else
    docker plugin set glusterfs SERVERS=localhost,$(echo $(hostname) | sed s/\-1/\-0/)
fi

docker plugin enable glusterfs
docker plugin install --alias s3fs mochoa/s3fs-volume-plugin --grant-all-permissions --disable

peer_ready() {
    gluster peer probe $1 > /dev/null 2>&1
}

volume_ready() {
    gluster v info myvolume > /dev/null 2>&1
}

mount_gluster_vol () {
    peer_host=$(echo $(hostname) | sed s/\-1/\-0/)
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
    peer_host=$(echo $(hostname) | sed s/\-0/\-1/)
    while !(peer_ready $peer_host)
    do
        sleep 3
    done
    sleep 10s
    gluster volume create myvolume replica 2 $(echo $(hostname) | sed s/\-0//)-{0,1}:/data/glusterfs/myvolume/mybrick/brick force
    gluster volume start myvolume
    sleep 10s
    mkdir -p /gluster-storage
    echo "localhost:/myvolume /gluster-storage glusterfs defaults,_netdev 0 0" >> /etc/fstab
    mount /gluster-storage && df -h
}

if [[ $(echo $(hostname) | grep "\-0$") ]]; then
    create_gluster_vol
else
    mount_gluster_vol
    sleep 30s
    eval $(ssh -o "StrictHostKeyChecking no" root@$(echo $(hostname) | sed s/\-1/\-0/) docker swarm join-token manager | tail -2)
fi

######################################
echo "Finished running setup.sh"