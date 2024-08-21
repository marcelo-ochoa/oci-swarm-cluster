# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

variable "tenancy_ocid" {}
variable "region" {}
variable "compartment_ocid" {}
variable "user_email" {}

variable "user_ocid" {
  default = ""
}
variable "fingerprint" {
  default = ""
}
variable "private_key_path" {
  default = ""
}

variable "public_ssh_key" {
  default = ""
}

# Compute
variable "num_nodes" {
  default = 2
}
variable "memory_in_gbs" {
  default = 12
}
variable "ocpus" {
  default = 2
}
variable "generate_public_ssh_key" {
  default = true
}
variable "instance_shape" {
  default = "VM.Standard.A1.Flex"
}
variable "image_operating_system" {
  default = "Oracle Linux"
}
variable "image_operating_system_version" {
  default = "8"
}
variable "instance_visibility" {
  default = "Public"
}
variable "is_pv_encryption_in_transit_enabled" {
  default = false
}

# Network Details
variable "lb_shape" {
  default = "flexible"
}
variable "lb_compartment_ocid" {
  default = ""
}
variable "create_secondary_vcn" {
  default = false
}
variable "create_lpg_policies_for_group" {
  default = false
}
variable "user_admin_group_for_lpg_policy" {
  default = "Administrators"
}
variable "network_cidrs" {
  type = map(string)

  default = {
    MAIN-VCN-CIDR                = "10.1.0.0/16"
    MAIN-SUBNET-REGIONAL-CIDR    = "10.1.21.0/24"
    MAIN-LB-SUBNET-REGIONAL-CIDR = "10.1.22.0/24"
    LB-VCN-CIDR                  = "10.2.0.0/16"
    LB-SUBNET-REGIONAL-CIDR      = "10.2.22.0/24"
    ALL-CIDR                     = "0.0.0.0/0"
  }
}

# Autonomous Database
variable "autonomous_database_name" {
  default = "OciSwarmDB"
}
variable "autonomous_database_db_version" {
  default = "19c"
}
variable "autonomous_database_license_model" {
  default = "LICENSE_INCLUDED"
}
variable "autonomous_database_is_free_tier" {
  default = true
}
variable "autonomous_database_cpu_core_count" {
  default = 1
}
variable "autonomous_database_data_storage_size_in_tbs" {
  default = 1
}
variable "autonomous_database_visibility" {
  default = "Public"
}
variable "oracle_client_version" {
  default = "19.10"
}

# Encryption (OCI Vault/Key Management/KMS)
variable "use_encryption_from_oci_vault" {
  default = false
}
variable "create_new_encryption_key" {
  default = true
}
variable "encryption_key_id" {
  default = ""
}
variable "create_vault_policies_for_group" {
  default = false
}
variable "user_admin_group_for_vault_policy" {
  default = "Administrators"
}
variable "vault_display_name" {
  default = "OciSwarm Vault"
}
variable "vault_type" {
  type    = list
  default = ["DEFAULT", "VIRTUAL_PRIVATE"]
}
variable "vault_key_display_name" {
  default = "OciSwarm Key"
}
variable "vault_key_key_shape_algorithm" {
  default = "AES"
}
variable "vault_key_key_shape_length" {
  default = 32
}

# Always Free only or support other shapes
variable "use_only_always_free_elegible_resources" {
  default = true
}

# ORM Schema visual control variables
variable "show_advanced" {
  default = false
}

# Object Storage
variable "object_storage_oci_swarm_media_compartment_ocid" {
  default = ""
}
variable "object_storage_oci_swarm_media_visibility" {
  default = "Public"
}

# OciSwarm Services
variable "services_in_mock_mode" {
  default = "carts,orders,users"
}
