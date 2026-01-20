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
  value = aws_eks_cluster.this.id

  description = <<-EOT
    The unique identifier (ID) of the AWS EKS cluster.
    Typically used to reference the cluster in scripts or cross-module resources.
  EOT
}

output "cluster_endpoint" {
  value = data.aws_eks_cluster.this.endpoint

  description = <<-EOT
    The public endpoint of the EKS cluster's Kubernetes API server.
    This value is required to configure `kubectl` or other Kubernetes clients to access the cluster.
  EOT
}

output "cluster_ca_certificate" {
  value = base64decode(
    one(data.aws_eks_cluster.this.certificate_authority[*].data)
  )

  description = <<-EOT
    The base64-decoded certificate authority (CA) data used to verify the EKS Kubernetes API server.
    Required when establishing secure (TLS) communication with the cluster.
  EOT
}

output "cluster_token" {
  value     = data.aws_eks_cluster_auth.this.token
  sensitive = true

  description = <<-EOT
    A temporary authentication token used to access the EKS Kubernetes API.
    This token is valid for 15 minutes and should be treated as sensitive.
    Typically used as a Bearer token in Kubernetes client configuration.
  EOT
}

output "eso_role_arn" {
  value = var.enable_external_secrets ? one(aws_iam_role.eso[*].arn) : null

  description = <<-EOT
    ARN of the IAM role for External Secrets Operator.
    Used to configure IRSA for the ESO service account.
  EOT
}
