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

resource "openstack_containerinfra_clustertemplate_v1" "this" {
  name                  = "kubernetes-v1.32.5"
  image                 = "Fedora-CoreOS-41"
  coe                   = "kubernetes"
  flavor                = data.openstack_compute_flavor_v2.m1_small.name
  master_flavor         = data.openstack_compute_flavor_v2.m1_medium.name
  dns_nameserver        = "1.1.1.1"
  docker_storage_driver = "overlay2"
  docker_volume_size    = 10
  volume_driver         = "cinder"
  network_driver        = "calico"
  server_type           = "vm"
  master_lb_enabled     = false
  floating_ip_enabled   = true

  external_network_id = data.openstack_networking_network_v2.external.id

  fixed_network = openstack_networking_network_v2.internal.id
  fixed_subnet  = values(openstack_networking_subnet_v2.internal)[0].id

  labels = {
    kube_tag = "v1.32.5-rancher1"
    etcd_tag = "v3.6.5"

    container_runtime         = "containerd"
    containerd_version        = "1.7.27"
    containerd_tarball_sha256 = "9fab9926e20ece5a0989c55a79b6e94c6d0927e06c287c2e0d80490b89da8237"

    coredns_tag = "1.13.1"
    calico_tag  = "v3.26.5"

    # OpenStack Cloud / CSI Components
    cinder_csi_plugin_tag         = "v1.34.1"
    k8s_keystone_auth_tag         = "v1.34.1"
    cloud_provider_tag            = "v1.34.1"
    magnum_auto_healer_tag        = "v1.34.1"
    csi_attacher_tag              = "v4.10.0"
    csi_resizer_tag               = "v1.14.0"
    csi_snapshotter_tag           = "v8.3.0"
    csi_provisioner_tag           = "v5.3.0"
    csi_node_driver_registrar_tag = "v2.15.0"
    csi_liveness_probe_tag        = "v2.17.0"

    keystone_auth_enabled  = true
    kube_dashboard_enabled = false

    influx_grafana_dashboard_enabled = false
    grafana_admin_passwd             = "admin"
    metrics_server_enabled           = true
    cloud_provider_enabled           = true

    ingress_controller                 = "nginx"
    nginx_ingress_controller_tag       = "1.13.3"
    nginx_ingress_controller_chart_tag = "v4.13.3"

    auto_healing_enabled    = true
    auto_healing_controller = "magnum-auto-healer"

    auto_scaling_enabled = false
  }
}

resource "openstack_containerinfra_cluster_v1" "this" {
  name                = var.cluster_name
  cluster_template_id = openstack_containerinfra_clustertemplate_v1.this.id
  master_count        = 1
  node_count          = 0
  keypair             = openstack_compute_keypair_v2.this.name

  depends_on = [
    openstack_networking_router_interface_v2.this,
  ]
}

resource "openstack_containerinfra_nodegroup_v1" "this" {
  name           = "app"
  cluster_id     = openstack_containerinfra_cluster_v1.this.id
  flavor_id      = data.openstack_compute_flavor_v2.m1_medium.id
  node_count     = var.cluster_desired_size
  min_node_count = var.cluster_min_size
  max_node_count = var.cluster_max_size

  labels = {
    kube_tag                      = "v1.32.5-rancher1"
    etcd_tag                      = "v3.6.5"
    container_runtime             = "containerd"
    containerd_version            = "1.7.27"
    containerd_tarball_sha256     = "9fab9926e20ece5a0989c55a79b6e94c6d0927e06c287c2e0d80490b89da8237"
    coredns_tag                   = "1.13.1"
    calico_tag                    = "v3.26.5"
    cinder_csi_plugin_tag         = "v1.34.1"
    k8s_keystone_auth_tag         = "v1.34.1"
    cloud_provider_tag            = "v1.34.1"
    magnum_auto_healer_tag        = "v1.34.1"
    csi_attacher_tag              = "v4.10.0"
    csi_resizer_tag               = "v1.14.0"
    csi_snapshotter_tag           = "v8.3.0"
    csi_provisioner_tag           = "v5.3.0"
    csi_node_driver_registrar_tag = "v2.15.0"
    csi_liveness_probe_tag        = "v2.17.0"
    auto_scaling_enabled          = true
  }

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}
