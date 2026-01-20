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

variable "gcp_region" {
  type    = string
  default = "us-central1-b"

  description = <<-EOT
    The Google Cloud region or zone where the GKE cluster is deployed.
    Example: "us-central1" or "us-central1-b"
  EOT

  validation {
    condition     = can(regex("^([a-z]+-[a-z]+[0-9]+)(-[a-z])?$", var.gcp_region))
    error_message = <<-EOT
      gcp_region must be a valid Google Cloud region (e.g., 'us-central1') 
      or zone (e.g., 'us-central1-b')
    EOT
  }
}

variable "cluster_name" {
  type    = string
  default = "application-gke"

  description = <<-EOT
    The name of the GKE cluster.
    This value is used to identify the cluster within GCP and should be unique
    within the selected project and region.
    Example: "application-gke"
  EOT
}

variable "enable_external_secrets" {
  type        = bool
  default     = true

  description = <<-EOT
    Enable Workload Identity for External Secrets Operator.
  EOT
}

variable "external_secrets_namespace" {
  type        = string
  default     = "external-secrets"

  description = <<-EOT
    Namespace where External Secrets Operator is installed.
  EOT
}
