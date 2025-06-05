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

resource "aws_eks_cluster" "this" {
  name = var.cluster_name

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster.arn
  version = (var.cluster_version != null
    ? var.cluster_version
    : local.default_cluster_version
  )

  vpc_config {
    subnet_ids = [
      for v in aws_subnet.this : v.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster,
  ]
}

resource "aws_eks_access_entry" "this" {
  cluster_name      = aws_eks_cluster.this.id
  principal_arn     = data.aws_caller_identity.current.arn
  kubernetes_groups = []
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "this" {
  cluster_name  = aws_eks_cluster.this.id
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_caller_identity.current.arn

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_node_group" "this" {
  node_group_name = "default"
  cluster_name    = aws_eks_cluster.this.id
  version         = aws_eks_cluster.this.version
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids = [
    for v in aws_subnet.this : v.id
  ]

  scaling_config {
    desired_size = var.cluster_desired_size
    max_size     = var.cluster_max_size
    min_size     = var.cluster_min_size
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group,
  ]
}
