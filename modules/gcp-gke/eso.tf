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

# Service account for External Secrets Operator
resource "google_service_account" "eso" {
  count = var.external_secrets_enabled ? 1 : 0

  account_id   = format("%s-eso", var.cluster_name)
  display_name = format("External Secrets Operator for %s", var.cluster_name)
}

# Grant Secret Manager access
resource "google_project_iam_member" "eso_secret_accessor" {
  count = var.external_secrets_enabled ? 1 : 0

  project = data.google_project.this.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = format("serviceAccount:%s", one(google_service_account.eso[*].email))
}

# Workload Identity binding
resource "google_service_account_iam_member" "eso_workload_identity" {
  count = var.external_secrets_enabled ? 1 : 0

  service_account_id = one(google_service_account.eso[*].name)
  role               = "roles/iam.workloadIdentityUser"
  member = format("serviceAccount:%s.svc.id.goog[%s/external-secrets]",
    data.google_project.this.project_id,
    var.external_secrets_namespace
  )
}
