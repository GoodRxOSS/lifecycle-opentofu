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

variable "cloudflare_api_token" {
  type    = string
  default = null

  validation {
    condition     = var.cloudflare_api_token == null || can(regex("^[A-Za-z0-9-_]{40,}$", var.cloudflare_api_token))
    error_message = <<-EOT
      cloudflare_api_token must be:
        - At least 40 characters long
        - Contain only letters (A-Z, a-z), digits (0-9), dashes (-), and underscores (_)
        - Be null if not used
    EOT
  }
}

variable "cloudflare_tunnel_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
    Controls whether to create and deploy the Cloudflare Tunnel resources.
  EOT
}

variable "cloudflare_tunnel_name" {
  type        = string
  default     = "lifecycle"
  description = <<-EOT
    The display name of the Cloudflare Tunnel.
    Used to identify the tunnel in the Zero Trust dashboard.
  EOT

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,63}$", var.cloudflare_tunnel_name))
    error_message = <<-EOT
      cloudflare_tunnel_name must be 1-63 characters long and 
      can only contain letters, numbers, underscores, and hyphens.
    EOT
  }
}

variable "cloudflare_tunnel_domain" {
  type        = string
  default     = null
  description = <<-EOT
    The domain name for the tunnel's ingress rules.
    If null, 'var.app_domain' will be used as a fallback.
  EOT

  validation {
    condition = (
      var.cloudflare_tunnel_domain == null
      ? true
      : can(regex("^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$",
        var.cloudflare_tunnel_domain)
      )
    )
    error_message = <<-EOT
      cloudflare_tunnel_domain must be a valid domain name (e.g., dev.example.com).
    EOT
  }
}

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

variable "gcp_project" {
  type        = string
  default     = null
  description = <<-EOT
    The Google Cloud Project ID to use for creating and managing resources.
    This should be the unique identifier of your GCP project.
    If not provided (null), some modules might attempt to infer the project from
    your environment or credentials.

    Format requirements:
      - Length between 6 and 30 characters
      - Lowercase letters, digits, and hyphens only
      - Must start with a lowercase letter
      - Cannot end with a hyphen
  EOT

  validation {
    condition = (
      var.gcp_project == null || (
        can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.gcp_project))
      )
    )
    error_message = <<-EOT
      gcp_project must be null or a valid GCP project ID: 6-30 chars, lowercase
      letters, digits, hyphens, start with letter, cannot end with hyphen
    EOT
  }
}

variable "gcp_credentials_file" {
  type    = string
  default = null

  validation {
    condition     = var.gcp_credentials_file == null || can(regex("^(~|\\./|/)?([^\\0]+)$", var.gcp_credentials_file))
    error_message = <<-EOT
      gcp_credentials_file must be a valid file path:
        - Can start with ~ (home directory), ./ (relative), or / (absolute)
        - Cannot be empty or contain null characters
    EOT
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

variable "aws_profile" {
  type    = string
  default = "default"

  description = <<-EOT
    The AWS CLI profile name to use for authentication and authorization
    when interacting with AWS services. This profile should be configured
    in your AWS credentials file (usually located at ~/.aws/credentials).

    The profile name must:
      - Be a non-empty string
      - Contain only alphanumeric characters, underscores (_), hyphens (-), and dots (.)
      - Start and end with an alphanumeric character

    Example valid profile names:
      - default
      - lifecycle-oss-eks
      - my_profile-1

    Note: Make sure the profile exists and has the necessary permissions.
  EOT

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]*[a-zA-Z0-9])?$", var.aws_profile))
    error_message = <<-EOT
      aws_profile must be a non-empty string containing only letters, digits, dots (.), 
      underscores (_) or hyphens (-), and start/end with a letter or digit.
    EOT
  }
}

variable "cluster_provider" {
  type    = string
  default = "eks"

  validation {
    condition     = contains(["gke", "eks"], var.cluster_provider)
    error_message = "cluster_provider must be either 'gke' or 'eks'"
  }
}

variable "dns_provider" {
  type    = string
  default = "route53"

  validation {
    condition     = contains(["route53", "cloud-dns", "cloudflare"], var.dns_provider)
    error_message = "dns_provider must be either 'route53', 'cloud-dns' or 'cloudflare'"
  }
}

variable "cluster_name" {
  type    = string
  default = "k8s-cluster"

  description = <<-EOT
    The name of the Kubernetes cluster.
    Must consist of alphanumeric characters, dashes, and be 1–100 characters long.
  EOT

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,100}$", var.cluster_name))
    error_message = <<-EOT
      Cluster name must be 1–100 characters long and consist of letters, numbers, dashes, or underscores
    EOT
  }
}


variable "private_registries" {
  type = list(object({
    url      = string
    username = string
    password = string
    usage    = list(string) # ["charts", "images"]
  }))
  default   = []
  sensitive = true

  description = <<-EOT
    Configuration for private registries (Helm charts and Container images).
    If empty, no registry blocks will be created.
  EOT

  validation {
    condition = alltrue([
      for r in var.private_registries : (
        can(regex("^([a-zA-Z0-9.-]+(:[0-9]+)?)$", r.url)) &&
        length(r.username) > 0 &&
        length(r.password) > 0
      )
    ])
    error_message = <<-EOT
      Invalid private registry configuration.
      Requirements:
      - url must be a valid domain or IP (e.g., 'ghcr.io', 'index.docker.io', '10.0.0.1:5000') without protocol.
      - username and password cannot be empty.
    EOT
  }

  validation {
    condition = alltrue([
      for r in var.private_registries : alltrue([
        for u in r.usage : contains(["charts", "images"], u)
      ])
    ])
    error_message = "The 'usage' field must only contain 'charts' and/or 'images'."
  }
}

variable "app_namespace" {
  type    = string
  default = "application-env"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.app_namespace)) && length(var.app_namespace) <= 63
    error_message = <<-EOT
      app_namespace must be a valid Kubernetes namespace name:
        - 1 to 63 characters long
        - lowercase letters, digits, and hyphens only
        - must start and end with a letter or digit
    EOT
  }
}

variable "app_enabled" {
  type        = bool
  default     = true
  description = <<-EOT
    Global toggle to enable or disable the entire application deployment.
  EOT
}

variable "app_domain" {
  type    = string
  default = "example.com"

  validation {
    condition     = can(regex("^([a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,}$", var.app_domain))
    error_message = "app_domain must be a valid domain name (e.g., example.com)"
  }
}

variable "app_subdomain" {
  type        = string
  default     = "app"
  description = <<-EOT
    Subdomain used to expose the Application module.
  EOT

  validation {
    condition     = length(trimspace(var.app_subdomain)) > 0
    error_message = "Application subdomain must not be empty."
  }
}

variable "app_postgres_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
    Toggle to control whether PostgreSQL is deployed.
  EOT
}

variable "app_lifecycle_enabled" {
  type        = bool
  default     = true
  description = <<-EOT
    Toggle to control whether PostgreSQL is deployed.
  EOT
}

variable "app_postgres_port" {
  type        = number
  default     = 5432
  description = <<-EOT
    Port used to connect to the PostgreSQL service.
  EOT

  validation {
    condition     = var.app_postgres_port > 0 && var.app_postgres_port < 65536
    error_message = "PostgreSQL port must be between 1 and 65535."
  }
}

variable "app_postgres_database" {
  type        = string
  default     = "lifecycle"
  description = <<-EOT
    Name of the PostgreSQL database to create and use.
  EOT

  validation {
    condition     = length(trimspace(var.app_postgres_database)) > 0
    error_message = "PostgreSQL database name must not be empty."
  }
}

variable "app_postgres_username" {
  type        = string
  default     = "lifecycle"
  description = <<-EOT
    Username for accessing the PostgreSQL database.
  EOT

  validation {
    condition     = length(trimspace(var.app_postgres_username)) > 0
    error_message = "PostgreSQL username must not be empty."
  }
}

variable "app_redis_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
    Toggle to control whether Redis is deployed.
  EOT
}

variable "app_redis_port" {
  type        = number
  default     = 6379
  description = <<-EOT
    Port used to connect to the Redis service.
  EOT

  validation {
    condition     = var.app_redis_port > 0 && var.app_redis_port < 65536
    error_message = "Redis port must be between 1 and 65535."
  }
}

variable "app_distribution_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
    Toggle to enable or disable the distribution module (e.g., API, frontend).
  EOT
}

variable "app_distribution_subdomain" {
  type        = string
  default     = "distribution"
  description = <<-EOT
    Subdomain used to expose the distribution module.
  EOT

  validation {
    condition     = length(trimspace(var.app_distribution_subdomain)) > 0
    error_message = "Distribution subdomain must not be empty."
  }
}

variable "app_buildkit_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
    Toggle to control whether BuildKit is deployed (e.g., for image builds).
  EOT
}

variable "keycloak_operator_enabled" {
  type        = bool
  default     = true
  description = <<-EOT
    Toggle to control whether Keycloak Operator is deployed.
  EOT
}

variable "app_lifecycle_keycloak" {
  type        = bool
  default     = true
  description = <<-EOT
    Toggle to control whether Keycloak instance for Lifecycle is deployed.
  EOT
}

variable "app_lifecycle_ui" {
  type        = bool
  default     = true
  description = <<-EOT
    Toggle to control whether Lifecycle UI is deployed.
  EOT
}
