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

# Module defifnitions

module "eks" {
  count = var.cluster_provider == "eks" ? 1 : 0

  source = "./modules/aws-eks"

  providers = {
    aws = aws.alias["0"]
  }

  cluster_name               = var.cluster_name
  enable_external_secrets    = var.enable_external_secrets
  external_secrets_namespace = var.external_secrets_namespace
}

module "gke" {
  count = var.cluster_provider == "gke" ? 1 : 0

  source = "./modules/gcp-gke"

  providers = {
    google = google.alias["0"]
  }

  gcp_region                 = var.gcp_region
  cluster_name               = var.cluster_name
  enable_external_secrets    = var.enable_external_secrets
  external_secrets_namespace = var.external_secrets_namespace
}

module "route53" {
  count = var.dns_provider == "route53" ? 1 : 0

  source = "./modules/aws-route53"

  providers = {
    aws = aws.alias["0"]
  }

  dns_domain       = var.app_domain
  dns_record_type  = local.public_endpoint.record_type
  dns_record_value = local.public_endpoint.record_value
}

module "cloud_dns" {
  count = var.dns_provider == "cloud-dns" ? 1 : 0

  source = "./modules/gcp-cloud-dns"

  providers = {
    google = google.alias["0"]
  }

  gcp_project      = var.gcp_project
  dns_domain       = var.app_domain
  dns_record_type  = local.public_endpoint.record_type
  dns_record_value = local.public_endpoint.record_value
}

module "cloudflare" {
  count = var.dns_provider == "cloudflare" ? 1 : 0

  source = "./modules/cloudflare-dns"

  dns_domain       = var.app_domain
  dns_record_type  = local.public_endpoint.record_type
  dns_record_value = local.public_endpoint.record_value
}
