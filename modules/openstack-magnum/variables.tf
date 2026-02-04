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

variable "region" {
  type        = string
  default     = "RegionOne"
  description = <<-EOT
    The name of the OpenStack region. Standard default is RegionOne.
  EOT

  validation {
    condition = (
      can(regex("^[a-zA-Z0-9_-]{3,64}$", var.region))
    )
    error_message = <<EOT
      The "region" name is invalid.
      Requirements:
      - 3 to 64 characters long.
      - Can contain letters (a-z, A-Z), digits (0-9), hyphens (-), and underscores (_).
      - Must match the region name defined in your OpenStack Keystone catalog.
    EOT
  }
}

variable "project" {
  type        = string
  default     = null
  description = <<-EOT
    The name of the OpenStack project (tenant). 
    Must be URL-safe and follow corporate naming conventions.
  EOT

  validation {
    condition = (
      var.project == null || (
        can(regex("^[a-z][a-z0-9-]{1,28}[a-z0-9]$", var.project)) &&
        !contains(["admin", "services", "service", "demo"], lower(var.project))
      )
    )
    error_message = <<EOT
      The "project" name is invalid.
      Requirements:
      - 3 to 30 characters long.
      - Start with a lowercase letter.
      - Contain only lowercase letters, digits, or hyphens.
      - Cannot end with a hyphen.
      - Cannot be a reserved name (admin, services, service, demo).
    EOT
  }
}

variable "cluster_name" {
  type    = string
  default = "k8s"

  description = <<-EOT
    The name of the OpenStack Magnum COE (Container Orchestration Engine) cluster.
    This name is used to identify the cluster within the OpenStack project and will 
    be visible in the 'openstack coe cluster list' output.
    Must start with a letter and contain only alphanumeric characters or dashes.
  EOT

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,62}$", var.cluster_name))
    error_message = <<-EOT
      The cluster_name must start with a letter, contain only alphanumeric characters 
      or dashes, and be between 1 and 63 characters long.
    EOT
  }
}

variable "network_internal_name" {
  type        = string
  default     = "internal"
  description = <<-EOT
    The name of the OpenStack internal network. Used as the 'name' attribute for the network resource.
  EOT

  validation {
    condition = (
      can(regex("^[a-z][a-z0-9-]{1,62}[a-z0-9]$", var.network_internal_name))
    )
    error_message = <<EOT
      The network_internal_name is invalid.
      Requirements:
      - 3 to 64 characters long.
      - Must start with a lowercase letter.
      - Can only contain lowercase letters, digits, and hyphens.
      - Cannot end with a hyphen.
    EOT
  }
}

variable "network_subnets" {
  type = map(string)
  default = {
    "internal-1" = "192.168.111.0/24"
    "internal-2" = "192.168.112.0/24"
    "internal-3" = "192.168.113.0/24"
  }

  description = <<-EOT
    A map of subnet names to CIDR blocks used within the network.
    The key is the subnet name (must be URL-safe), and the value is a valid IPv4 CIDR.
  EOT

  validation {
    condition = alltrue([
      for name, cidr in var.network_subnets : (
        can(cidrnetmask(cidr)) &&
        can(regex("^[a-z][a-z0-9-]{1,62}[a-z0-9]$", name))
      )
    ])
    error_message = <<EOT
      Invalid subnet configuration.
      Requirements for each subnet:
      - CIDR must be a valid IPv4 block (e.g., 10.0.0.0/24).
      - Name (key) must be 3 to 64 characters long.
      - Name (key) must start with a lowercase letter.
      - Name (key) can only contain lowercase letters, digits, and hyphens.
      - Name (key) cannot end with a hyphen.
    EOT
  }
}

variable "network_external_name" {
  type        = string
  default     = "external"
  description = <<-EOT
    The name of the OpenStack external network. Used as the 'name' attribute for the network resource.
  EOT

  validation {
    condition = (
      can(regex("^[a-z][a-z0-9-]{1,62}[a-z0-9]$", var.network_external_name))
    )
    error_message = <<EOT
      The network_external_name is invalid.
      Requirements:
      - 3 to 64 characters long.
      - Must start with a lowercase letter.
      - Can only contain lowercase letters, digits, and hyphens.
      - Cannot end with a hyphen.
    EOT
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
  default = 2

  description = <<EOT
    The minimum number of nodes in the EKS node group.
    Cluster autoscaler or node group logic will not scale below this value.
  EOT

  validation {
    condition     = var.cluster_min_size >= 1
    error_message = "Min size must be at least 1"
  }
}

variable "ssh_public_key" {
  type        = string
  default     = null
  description = <<-EOT
    The content of the SSH public key (e.g., contents of ~/.ssh/id_rsa.pub). 
    Supports RSA, ECDSA, and ED25519 formats.
  EOT

  validation {
    condition = (
      var.ssh_public_key == null ||
      can(regex("^(ssh-(rsa|ed25519|ecdsa-sha2-nistp256|sha2-nistp384|sha2-nistp521)) [A-Za-z0-9+/]+[=]{0,3}( .+)?$", var.ssh_public_key))
    )
    error_message = <<EOT
      The ssh_public_key must be a valid OpenSSH public key format 
      (starting with ssh-rsa, ssh-ed25519, etc.).
    EOT
  }
}

variable "ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_rsa.pub"
  description = <<-EOT
    The local filesystem path to the SSH public key file.
  EOT

  validation {
    condition = (
      can(regex("^(/|./|../|[a-zA-Z]:).+$", var.ssh_public_key_path))
    )
    error_message = <<EOT
      The ssh_public_key_path must be a valid absolute or relative filesystem path.
    EOT
  }
}
