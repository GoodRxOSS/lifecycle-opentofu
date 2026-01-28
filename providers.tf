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

# Providers configuration

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "aws" {
  for_each = (var.cluster_provider == "eks" || var.dns_provider == "route53"
    ? toset(["0"]) : []
  )

  alias = "alias"

  region  = var.aws_region
  profile = var.aws_profile
}

provider "google" {
  for_each = (var.cluster_provider == "gke" || var.dns_provider == "cloud-dns"
    ? toset(["0"]) : []
  )

  alias = "alias"

  project = var.gcp_project
  region  = var.gcp_region
  credentials = (
    var.gcp_credentials_file != null
    ? file(var.gcp_credentials_file)
    : null
  )
}

provider "kubernetes" {
  host                   = local.cluster.endpoint
  cluster_ca_certificate = local.cluster.ca_certificate
  token                  = local.cluster.token
}

provider "kubectl" {
  host                   = local.cluster.endpoint
  cluster_ca_certificate = local.cluster.ca_certificate
  token                  = local.cluster.token
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = local.cluster.endpoint
    cluster_ca_certificate = local.cluster.ca_certificate
    token                  = local.cluster.token
  }

  dynamic "registry" {
    for_each = [
      for v in var.private_registries : v if contains(v.usage, "charts")
    ]

    content {
      url      = format("oci://%s", registry.value.url)
      username = registry.value.username
      password = registry.value.password
    }
  }
}
