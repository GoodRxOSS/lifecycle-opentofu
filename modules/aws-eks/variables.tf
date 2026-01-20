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

variable "cluster_name" {
  type    = string
  default = "eks-cluster"

  description = <<-EOT
    The name of the Amazon EKS cluster.
    Used to identify the cluster across AWS services and Terraform resources.
    Must consist of alphanumeric characters, dashes, and be 1–100 characters long.
  EOT

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,100}$", var.cluster_name))
    error_message = "Cluster name must be 1–100 characters long and consist of letters, numbers, dashes, or underscores"
  }
}

variable "cluster_version" {
  type    = string
  default = null

  description = <<-EOT
    The Kubernetes version to use for the EKS control plane.
    If not specified, AWS will use the default version.
    Example valid values: "1.27", "1.28", "1.29"
  EOT

  validation {
    condition     = var.cluster_version == null || can(regex("^1\\.(2[0-7-9])$", var.cluster_version))
    error_message = "EKS version must be in the format '1.27', '1.28', etc., or null to use default"
  }
}

variable "aws_region" {
  type    = string
  default = "us-west-2"

  description = <<-EOT
    The AWS region where the EKS cluster and related resources will be deployed.
    Example: "us-east-1", "eu-west-1", "us-west-2"
  EOT

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be in the format like 'us-west-2', 'eu-central-1', etc"
  }
}

variable "vpc_cidr" {
  type    = string
  default = "172.32.0.0/16"

  description = <<-EOT
    The CIDR block for the VPC to be used by the EKS cluster.
    Must be a valid CIDR notation (e.g., 10.0.0.0/16).
  EOT

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "VPC CIDR must be a valid CIDR block, like 172.32.0.0/16"
  }
}

variable "vpc_subnets" {
  type = map(string)
  default = {
    a = "172.32.0.0/20"
    b = "172.32.16.0/20"
    c = "172.32.32.0/20"
  }

  description = <<-EOT
    A map of subnet names to CIDR blocks used within the VPC.
    These subnets should be in separate availability zones to enable high availability.
  EOT

  validation {
    condition = alltrue([
      for cidr in values(var.vpc_subnets) : can(cidrnetmask(cidr))
    ])
    error_message = "Each subnet must be a valid CIDR block, like 172.32.0.0/20"
  }
}

variable "cluster_desired_size" {
  type    = number
  default = 2

  description = <<-EOT
    The desired number of worker nodes in the node group at startup.
    This sets the initial node count in the EKS node group.
  EOT

  validation {
    condition     = var.cluster_desired_size >= 1
    error_message = "Desired size must be at least 1"
  }
}

variable "cluster_max_size" {
  type    = number
  default = 7

  description = <<EOT
    The maximum number of nodes the EKS node group can scale up to.
    Useful for configuring cluster autoscaler or other capacity limits.
  EOT

  validation {
    condition     = var.cluster_max_size >= var.cluster_desired_size
    error_message = "Max size must be greater than or equal to desired size"
  }
}

variable "cluster_min_size" {
  type    = number
  default = 1

  description = <<EOT
    The minimum number of nodes in the EKS node group.
    Cluster autoscaler or node group logic will not scale below this value.
  EOT

  validation {
    condition     = var.cluster_min_size >= 1
    error_message = "Min size must be at least 1"
  }
}

variable "enable_external_secrets" {
  type        = bool
  default     = true

  description = <<-EOT
    Enable IRSA role for External Secrets Operator.
  EOT
}

variable "external_secrets_namespace" {
  type        = string
  default     = "external-secrets"

  description = <<-EOT
    Namespace where External Secrets Operator is installed.
  EOT
}
