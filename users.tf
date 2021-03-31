# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

resource "oci_identity_user" "oci_user" {
    #Required
    compartment_id = var.tenancy_ocid
    description = "Swarm User to access Cloud Storage"
    name = "swarm-${random_string.deploy_id.result}"
}

resource "oci_identity_user_capabilities_management" "oci_user" {
    #Required
    user_id = oci_identity_user.oci_user.id

    #Optional 
    can_use_api_keys             = "true"
    can_use_auth_tokens          = "false"
    can_use_console_password     = "false"
    can_use_customer_secret_keys = "true"
    can_use_smtp_credentials     = "false"
}

resource "oci_identity_customer_secret_key" "oci_user" {
    #Required
    display_name = "s3_bucket"
    user_id = oci_identity_user.oci_user.id
}

resource "oci_identity_user_group_membership" "oci_user" {
    #Required
    group_id = oci_identity_group.storage_admins.id
    user_id = oci_identity_user.oci_user.id
}