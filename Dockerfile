#
# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

# Runtime Image
FROM alpine:latest
# Oracle Instant Client version
ARG oracleClientVersion=19.8
WORKDIR /

# Create ORM package
COPY VERSION /
WORKDIR /basic
COPY terraform/*.tf /basic/
COPY terraform/*.tfvars.example /basic/
COPY terraform/schema.yaml /basic/
COPY terraform/scripts /basic/scripts
COPY images /basic/images
RUN apk update && apk add zip
RUN mkdir /package && zip -r /package/oci-swarm-stack.zip .

VOLUME ["/usr/lib/oracle/${oracleClientVersion}/client64/lib/network/admin/"]
VOLUME ["/transfer/"]

#    ----- Base Image ------  #
