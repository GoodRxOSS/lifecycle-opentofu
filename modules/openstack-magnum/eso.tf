# Copyright 2026 GoodRx, Inc.
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

resource "openstack_identity_application_credential_v3" "eso" {
  count = var.external_secrets_enabled ? 1 : 0

  region      = var.region
  name        = "eso-barbican-reader"
  description = "Application Credential for External Secrets Operator"

  roles = [
    "reader",
    "observer",
  ]
}
