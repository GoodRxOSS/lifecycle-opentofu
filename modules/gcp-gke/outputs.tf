# Copyright 2025 GoodRx, Inc.
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
  value = google_container_cluster.this.name

  description = <<-EOT
    The name of the created Google Kubernetes Engine (GKE) cluster.
    Useful for referencing the cluster by name in external modules or scripts.
  EOT
}

output "cluster_endpoint" {
  value = format("https://%s", google_container_cluster.this.endpoint)

  description = <<-EOT
    The public endpoint URL used to connect to the GKE cluster's Kubernetes API server.
    This value is required when configuring kubectl or other Kubernetes clients.
  EOT
}

output "cluster_ca_certificate" {
  value = base64decode(
    one(google_container_cluster.this.master_auth[*].cluster_ca_certificate)
  )

  description = <<-EOT
    The base64-decoded certificate authority (CA) certificate for the GKE cluster.
    Used for securely verifying the cluster's API server identity when authenticating clients.
  EOT
}

output "cluster_token" {
  value     = data.google_client_config.this.access_token
  sensitive = true

  description = <<-EOT
    The OAuth2 access token for the active Google Cloud user account.
    This token can be used for authenticating against the Kubernetes API,
    typically passed as a Bearer token in client requests. Marked as sensitive.
  EOT
}
