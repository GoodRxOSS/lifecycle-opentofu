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

# Locals and helpers

locals {
  cluster = (
    var.cluster_provider == "eks" ? {
      name           = one(module.eks[*].cluster_name)
      endpoint       = one(module.eks[*].cluster_endpoint)
      ca_certificate = one(module.eks[*].cluster_ca_certificate)
      token          = one(module.eks[*].cluster_token)
    } :
    var.cluster_provider == "gke" ? {
      name           = one(module.gke[*].cluster_name)
      endpoint       = one(module.gke[*].cluster_endpoint)
      ca_certificate = one(module.gke[*].cluster_ca_certificate)
      token          = one(module.gke[*].cluster_token)
    } :
  {})

  public_endpoint = (
    var.cluster_provider == "eks" ? {
      record_type  = "CNAME"
      record_value = data.kubernetes_service.ingress_nginx_controller.status[0].load_balancer[0].ingress[0].hostname
    } :
    var.cluster_provider == "gke" ? {
      record_type  = "A"
      record_value = data.kubernetes_service.ingress_nginx_controller.status[0].load_balancer[0].ingress[0].ip
    } :
    {
      record_type  = "A"
      record_value = "example.com"
    }
  )
}

locals {
  helper = (
    var.cluster_provider == "eks" ? {
      kubeconfig_update_cmd = format(
        "aws eks update-kubeconfig --name %s --region %s --profile %s",
        var.cluster_name, var.aws_region, var.aws_profile
      )
    } :
    var.cluster_provider == "gke" ? {
      kubeconfig_update_cmd = format(
        "gcloud container clusters get-credentials %s --zone %s --project %s",
        var.cluster_name, var.gcp_region, var.gcp_project
      )
    } :
    {
      kubeconfig_update_cmd = null
    }
  )
  help = <<-EOT
    Quick help of usage [${var.cluster_provider}]:
      - Update `kubeconfig` file:
          $ ${local.helper.kubeconfig_update_cmd}

      - Check cluster permissions, e.g. List Pods in `${var.app_namespace}` namespace
          $ kubectl -n ${var.app_namespace} get pods

      - Check public endpoint, DNS, certificates etc.
          $ curl -v https://kuard.${var.app_domain}
  EOT
}
