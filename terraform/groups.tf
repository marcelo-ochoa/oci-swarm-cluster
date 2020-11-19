# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

resource "oci_identity_group" "storage_admins" {
  description    = "Group for users allowed manage the Storage resources in the tenancy."
  name           = "StorageAdmins.grp"
  compartment_id = var.compartment_ocid
}
