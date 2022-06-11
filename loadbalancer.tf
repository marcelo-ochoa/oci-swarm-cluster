# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

resource "oci_load_balancer_load_balancer" "oci_swarm_lb" {
  compartment_id = (var.lb_compartment_ocid != "") ? var.lb_compartment_ocid : var.compartment_ocid
  display_name   = "oci-swarm-${random_string.deploy_id.result}"
  shape          = var.lb_shape
  subnet_ids     = [oci_core_subnet.oci_swarm_lb_subnet.id]
  is_private     = "false"
  freeform_tags  = local.common_tags
  # Choose flexible as shape in var.lb_shape
  shape_details {
        #Required
        maximum_bandwidth_in_mbps = 10
        minimum_bandwidth_in_mbps = 10
    }
}

resource "oci_load_balancer_backend_set" "oci_swarm_bes" {
  name             = "oci-swarm-${random_string.deploy_id.result}"
  load_balancer_id = oci_load_balancer_load_balancer.oci_swarm_lb.id
  policy           = "IP_HASH"

  health_checker {
    port                = "80"
    protocol            = "HTTP"
    response_body_regex = ".*"
    url_path            = "/whoami"
    return_code         = 200
    interval_ms         = 5000
    timeout_in_millis   = 2000
    retries             = 10
  }
}

resource "oci_load_balancer_backend" "oci-swarm-be" {
  load_balancer_id = oci_load_balancer_load_balancer.oci_swarm_lb.id
  backendset_name  = oci_load_balancer_backend_set.oci_swarm_bes.name
  ip_address       = element(oci_core_instance.app_instance.*.private_ip, count.index)
  port             = 80
  backup           = false
  drain            = false
  offline          = false
  weight           = 1

  count = (var.num_nodes > 2) ? 2 : var.num_nodes
}

resource "oci_load_balancer_backend_set" "oci_swarm_bes_ssl" {
  name             = "oci-swarm-ssl-${random_string.deploy_id.result}"
  load_balancer_id = oci_load_balancer_load_balancer.oci_swarm_lb.id
  policy           = "IP_HASH"

  health_checker {
    port                = "80"
    protocol            = "HTTP"
    response_body_regex = ".*"
    url_path            = "/whoami"
    return_code         = 200
    interval_ms         = 5000
    timeout_in_millis   = 2000
    retries             = 10
  }
}

resource "oci_load_balancer_backend" "oci-swarm-be_ssl" {
  load_balancer_id = oci_load_balancer_load_balancer.oci_swarm_lb.id
  backendset_name  = oci_load_balancer_backend_set.oci_swarm_bes_ssl.name
  ip_address       = element(oci_core_instance.app_instance.*.private_ip, count.index)
  port             = 443
  backup           = false
  drain            = false
  offline          = false
  weight           = 1

  count = (var.num_nodes > 2) ? 2 : var.num_nodes
}

resource "oci_load_balancer_listener" "oci_swarm_listener_80" {
  load_balancer_id         = oci_load_balancer_load_balancer.oci_swarm_lb.id
  default_backend_set_name = oci_load_balancer_backend_set.oci_swarm_bes.name
  name                     = "oci-swarm-${random_string.deploy_id.result}-80"
  port                     = 80
  protocol                 = "TCP"

  connection_configuration {
    idle_timeout_in_seconds = "30"
  }
}

resource "oci_load_balancer_listener" "oci_swarm_listener_443" {
  load_balancer_id         = oci_load_balancer_load_balancer.oci_swarm_lb.id
  default_backend_set_name = oci_load_balancer_backend_set.oci_swarm_bes_ssl.name
  name                     = "oci-swarm-${random_string.deploy_id.result}-443"
  port                     = 443
  protocol                 = "TCP"

  connection_configuration {
    idle_timeout_in_seconds = "30"
  }
}