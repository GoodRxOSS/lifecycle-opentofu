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

data "openstack_identity_project_v3" "this" {
  name = var.project
}

data "openstack_compute_flavor_v2" "m1_small" {
  name = "m1.small"
}

data "openstack_compute_flavor_v2" "m1_medium" {
  name = "m1.medium"
}
