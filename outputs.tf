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

output "help" {
  value       = local.help
  description = <<-EOT
    Quick help of usage
  EOT
}

output "kubeconfig" {
  value       = local.cluster.kubeconfig
  sensitive   = true
  description = <<-EOT
    The Kubernetes configuration file (kubeconfig) for the Magnum cluster.
    This configuration is primarily generated based on the client certificates, 
    private keys, and CA data provided by the OpenStack Magnum API.
    It provides 'kubectl' with the necessary credentials to authenticate 
    and manage the cluster with administrative privileges.
  EOT
}
