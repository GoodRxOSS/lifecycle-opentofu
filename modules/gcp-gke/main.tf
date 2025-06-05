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
  account_id   = "runtime-sa"
  display_name = "Runtime SA"
}

resource "google_project_iam_member" "metrics" {
  project = data.google_project.this.project_id
  role    = "roles/monitoring.metricWriter"
  member = format("serviceAccount:%s-compute@developer.gserviceaccount.com",
    data.google_project.this.number
  )
}

resource "google_container_cluster" "this" {
  name     = var.cluster_name
  location = var.gcp_region

  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false

  node_config {
    disk_size_gb = 20
    disk_type    = "pd-standard"
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  lifecycle {
    ignore_changes = [
      node_config,
    ]
  }
}

resource "google_container_node_pool" "default" {
  name     = "default"
  location = var.gcp_region
  cluster  = google_container_cluster.this.name

  autoscaling {
    location_policy      = "BALANCED"
    max_node_count       = 7
    min_node_count       = 2
    total_max_node_count = 0
    total_min_node_count = 0
  }

  node_config {
    preemptible  = true
    machine_type = "e2-medium"
    disk_size_gb = 30
    disk_type    = "pd-balanced"

    service_account = google_service_account.this.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
