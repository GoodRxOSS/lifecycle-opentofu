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

output "cluster_name" {
  value = openstack_containerinfra_cluster_v1.this.name

  description = <<-EOT
    The name of the OpenStack Magnum Kubernetes cluster. 
    Used to identify the cluster within the Container Infrastructure Management service.
  EOT
}

output "cluster_endpoint" {
  value = openstack_containerinfra_cluster_v1.this.kubeconfig.host

  description = <<-EOT
    The Kubernetes API server endpoint URL. 
    This is the address used by kubectl and other clients to communicate with the cluster control plane.
  EOT
}

output "cluster_ca_certificate" {
  value = openstack_containerinfra_cluster_v1.this.kubeconfig.cluster_ca_certificate

  description = <<-EOT
    The Root CA certificate (PEM format) used to verify the TLS connection to the cluster API server.
    Required for secure communication and to prevent man-in-the-middle attacks.
  EOT
}

output "cluster_client_certificate" {
  value     = openstack_containerinfra_cluster_v1.this.kubeconfig.client_certificate
  sensitive = true

  description = <<-EOT
    The client certificate (PEM format) used for authenticating the user or service account against the Kubernetes API.
    Combined with the client key, it provides identity for the connection.
  EOT
}

output "cluster_client_key" {
  value     = openstack_containerinfra_cluster_v1.this.kubeconfig.client_key
  sensitive = true

  description = <<-EOT
    The private key for the client certificate. 
    This is a sensitive value used for cryptographic authentication to the cluster.
  EOT
}

output "cluster_raw_config" {
  value     = openstack_containerinfra_cluster_v1.this.kubeconfig.raw_config
  sensitive = true

  description = <<-EOT
    The full, ready-to-use Kubeconfig file in YAML format. 
    Contains all necessary credentials, endpoints, and context to access the cluster immediately.
  EOT
}
