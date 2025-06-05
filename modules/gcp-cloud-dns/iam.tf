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

resource "google_service_account" "this" {
  account_id   = "cert-manager-dns"
  display_name = "Cert Manager DNS Solver"
  project      = var.gcp_project
}

resource "google_project_iam_custom_role" "this" {
  role_id     = "certManager"
  title       = "CertManager"
  description = "Cert Manager"
  project     = var.gcp_project

  permissions = [
    "dns.managedZones.list",
    "dns.resourceRecordSets.create",
    "dns.resourceRecordSets.delete",
    "dns.resourceRecordSets.get",
    "dns.resourceRecordSets.list",
    "dns.changes.create",
    "dns.changes.get",
    "dns.changes.list",
  ]
}

resource "google_project_iam_member" "this" {
  project = var.gcp_project
  role    = google_project_iam_custom_role.this.name
  member  = format("serviceAccount:%s", google_service_account.this.email)
}

resource "google_service_account_key" "this" {
  service_account_id = google_service_account.this.name
  public_key_type    = "TYPE_NONE"
}
