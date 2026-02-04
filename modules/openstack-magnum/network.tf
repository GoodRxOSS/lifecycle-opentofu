# Copyright 2026 GoodRx, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource "openstack_networking_network_v2" "internal" {
  name                    = var.network_internal_name
  region                  = var.region
  tenant_id               = data.openstack_identity_project_v3.this.id
  admin_state_up          = true
  availability_zone_hints = []
  external                = false
  mtu                     = 1450
  port_security_enabled   = true
  shared                  = false
  transparent_vlan        = false
  tags                    = []
}

resource "openstack_networking_subnet_v2" "internal" {
  for_each = var.network_subnets

  name            = each.key
  region          = var.region
  tenant_id       = data.openstack_identity_project_v3.this.id
  network_id      = openstack_networking_network_v2.internal.id
  cidr            = each.value
  gateway_ip      = cidrhost(each.value, 1)
  dns_nameservers = []
  enable_dhcp     = true
  ip_version      = strcontains(each.value, ":") ? 6 : 4
  service_types   = []

  allocation_pool {
    start = cidrhost(each.value, 2)
    end   = cidrhost(each.value, -2)
  }

  tags = []
}

data "openstack_networking_network_v2" "external" {
  name = var.network_external_name
}

data "openstack_networking_subnet_v2" "external" {
  name = var.network_external_name
}

data "openstack_networking_subnet_ids_v2" "external" {
  network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_v2" "external" {
  name                    = var.network_external_name
  region                  = var.region
  tenant_id               = data.openstack_identity_project_v3.this.id
  external_network_id     = data.openstack_networking_network_v2.external.id
  admin_state_up          = true
  availability_zone_hints = []
  #   distributed             = false
  #   enable_snat             = true

  #   external_fixed_ip {
  #     ip_address = "172.16.1.111"
  #     subnet_id  = data.openstack_networking_subnet_v2.external.id
  #   }

  tags = []
}

resource "openstack_networking_router_interface_v2" "this" {
  for_each = var.network_subnets

  region    = var.region
  router_id = openstack_networking_router_v2.external.id
  subnet_id = openstack_networking_subnet_v2.internal[each.key].id
}
