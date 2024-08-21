# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

resource "oci_identity_group" "storage_admins" {
  description    = "Group to manage the Storage resources in the tenancy."
  name           = "StorageAdmins.grp"
  # https://docs.oracle.com/en-us/iaas/api/#/en/identity/20160918/Group/CreateGroup:
  # Creates a new group in your tenancy.
  # You must specify your tenancy's OCID as the compartment ID in the request object
  # (remember that the tenancy is simply the root compartment):
  compartment_id = var.tenancy_ocid
  # Fixes:
  # Error: 400-InvalidParameter, Tenant id is not equal to compartment id
  # Suggestion: Please update the parameter(s) in the Terraform config as per
  # error message Tenant id is not equal to compartment id
}
