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
        length(var.gcp_project) >= 6 &&
        length(var.gcp_project) <= 30 &&
        can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.gcp_project))
      )
    )
    error_message = <<-EOT
      gcp_project must be null or a valid GCP project ID: 6-30 chars, lowercase
      letters, digits, hyphens, start with letter, cannot end with hyphen
    EOT
  }
}

variable "dns_domain" {
  type = string

  description = <<-EOT
    The DNS domain name under which the DNS record will be created.
    Example: "example.com"
  EOT

  validation {
    condition     = can(regex("^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$", var.dns_domain))
    error_message = "dns_domain must be a valid domain name, e.g. example.com"
  }
}

variable "dns_record_name" {
  type    = string
  default = "*"

  description = <<-EOT
    The DNS record name (subdomain or hostname) to create or manage.
    Example: "www" or "app"
    Defaults to "*"
  EOT

  validation {
    condition     = can(regex("^([a-zA-Z0-9-_*]{1,63})$", var.dns_record_name))
    error_message = "dns_record_name must be 1-63 characters long and contain only letters, digits, hyphens, or underscores"
  }
}

variable "dns_record_value" {
  type = string

  description = <<-EOT
    The value of the DNS record, which can be:
      - An IPv4 address (e.g., 192.168.0.1)
      - An IPv6 address (e.g., 2001:0db8::1)
      - A hostname (e.g., example.com or sub.domain.local)
  EOT

  validation {
    condition = (
      can(regex("^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$", var.dns_record_value)) ||
      can(regex("^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$", var.dns_record_value)) ||
      can(regex("^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$", var.dns_record_value))
    )
    error_message = "dns_record_value must be a valid IPv4, IPv6 address, or a hostname like example.com"
  }
}

variable "dns_record_type" {
  type    = string
  default = "A"

  description = <<-EOT
    The DNS record type (e.g., A, AAAA, CNAME).
    Defaults to "A"
  EOT

  validation {
    condition     = contains(["A", "AAAA", "CNAME"], upper(var.dns_record_type))
    error_message = "dns_record_type must be one of A, AAAA, CNAME"
  }
}

variable "dns_ttl" {
  type    = number
  default = 60

  description = <<-EOT
    The TTL (time to live) for the DNS record in seconds.
    Must be a positive integer, typically between 30 and 86400.
    Defaults to 60 seconds.
  EOT

  validation {
    condition     = var.dns_ttl > 0 && var.dns_ttl <= 86400
    error_message = "dns_ttl must be a positive integer between 1 and 86400 seconds"
  }
}
