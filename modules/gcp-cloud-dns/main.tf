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

data "google_dns_managed_zones" "this" {}

locals {
  zone_name = try([
    for v in data.google_dns_managed_zones.this.managed_zones : v
    if v.dns_name == format("%s.", var.dns_domain) && v.visibility == "public"
  ][0]["name"], null)
}

resource "google_dns_record_set" "this" {
  managed_zone = local.zone_name
  name         = format("%s.%s.", var.dns_record_name, var.dns_domain)
  type         = var.dns_record_type
  ttl          = var.dns_ttl
  rrdatas = [
    var.dns_record_value
  ]
}
