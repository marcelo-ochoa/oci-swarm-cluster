# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

# For more information, see:
# https://hiteshgondalia.wordpress.com/2020/01/15/launch-oci-free-tier-atp-and-adw-using-terraform-on-window-platform/

# For references, see:
# https://library.tf/providers/oracle/oci/latest/docs/resources/database_autonomous_database
# https://docs.oracle.com/en-us/iaas/tools/terraform-provider-oci/6.7.0/docs/d/database_autonomous_databases.html


# ATP database
resource "oci_database_autonomous_database" "oci_swarm_autonomous_database" {

  # Required configuration setting for the autonomous_database free tier:
  is_free_tier                                   = true
  is_dedicated                                   = false
  is_auto_scaling_enabled                        = false
  is_auto_scaling_for_storage_enabled            = false
  is_preview_version_with_service_terms_accepted = false

  # General configuration
  admin_password           = random_string.autonomous_database_admin_password.result
  compartment_id           = var.compartment_ocid
  db_name                  = "${var.autonomous_database_name}${random_string.deploy_id.result}"
  display_name             = "${var.autonomous_database_name}-${random_string.deploy_id.result}"
  freeform_tags            = local.common_tags
  license_model            = "LICENSE_INCLUDED"
  nsg_ids                  = (var.autonomous_database_visibility == "Private") ? [oci_core_network_security_group.atp_nsg[0].id] : []
  subnet_id                = (var.autonomous_database_visibility == "Private") ? oci_core_subnet.oci_swarm_main_subnet.id : ""
}
