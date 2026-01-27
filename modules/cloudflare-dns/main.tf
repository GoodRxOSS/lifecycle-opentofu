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

locals {
  dns_domain_zone = join(".",
    slice(split(".", var.dns_domain),
      length(split(".", var.dns_domain)) - 2,
      length(split(".", var.dns_domain)),
    )
  )
}

data "cloudflare_zone" "this" {
  filter = {
    name = local.dns_domain_zone
  }
}

resource "cloudflare_dns_record" "this" {
  zone_id = data.cloudflare_zone.this.zone_id

  name = (
    var.dns_record_name == null || var.dns_record_name == ""
    ? var.dns_domain
    : format("%s.%s", var.dns_record_name, var.dns_domain)
  )

  type    = var.dns_record_type
  proxied = var.dns_proxied
  ttl     = var.dns_ttl
  content = var.dns_record_value
}
