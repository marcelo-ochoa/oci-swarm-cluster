# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

resource "oci_objectstorage_bucket" "swarm" {
  compartment_id = var.compartment_ocid
  name           = "oci-swarm-${random_string.deploy_id.result}"
  namespace      = data.oci_objectstorage_namespace.user_namespace.namespace
  freeform_tags  = local.common_tags
  kms_key_id     = var.use_encryption_from_oci_vault ? (var.create_new_encryption_key ? oci_kms_key.oci_swarm_key[0].id : var.encryption_key_id) : null
  depends_on     = [oci_identity_policy.oci_swarm_basic_policies]
}

resource "oci_objectstorage_object" "oci_swarm_wallet" {
  bucket    = oci_objectstorage_bucket.swarm.name
  content   = data.oci_database_autonomous_database_wallet.autonomous_database_wallet.content
  namespace = data.oci_objectstorage_namespace.user_namespace.namespace
  object    = "oci_swarm_atp_wallet"
}
resource "oci_objectstorage_preauthrequest" "oci_swarm_wallet_preauth" {
  access_type  = "ObjectRead"
  bucket       = oci_objectstorage_bucket.swarm.name
  name         = "oci_swarm_wallet_preauth"
  namespace    = data.oci_objectstorage_namespace.user_namespace.namespace
  time_expires = timeadd(timestamp(), "30m")
  object       = oci_objectstorage_object.oci_swarm_wallet.object
}

# Static assets bucket
resource "oci_objectstorage_bucket" "oci_swarm_media" {
  compartment_id = (var.object_storage_oci_swarm_media_compartment_ocid != "") ? var.object_storage_oci_swarm_media_compartment_ocid : var.compartment_ocid
  name           = "oci-swarm-media-${random_string.deploy_id.result}"
  namespace      = data.oci_objectstorage_namespace.user_namespace.namespace
  freeform_tags  = local.common_tags
  access_type    = (var.object_storage_oci_swarm_media_visibility == "Private") ? "NoPublicAccess" : "ObjectReadWithoutList"
  kms_key_id     = var.use_encryption_from_oci_vault ? (var.create_new_encryption_key ? oci_kms_key.oci_swarm_key[0].id : var.encryption_key_id) : null
}

# Static product media
resource "oci_objectstorage_object" "oci_swarm_media" {
  for_each = fileset("./images", "**")

  bucket        = oci_objectstorage_bucket.oci_swarm_media.name
  namespace     = oci_objectstorage_bucket.oci_swarm_media.namespace
  object        = each.value
  source        = "./images/${each.value}"
  content_type  = "image/png"
  cache_control = "max-age=604800, public, no-transform"
}
