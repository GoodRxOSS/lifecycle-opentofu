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

# IRSA role for External Secrets Operator
resource "aws_iam_role" "eso" {
  count = var.enable_external_secrets ? 1 : 0

  name = format("%s-eso", var.cluster_name)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.oidc.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          format("%s:sub", replace(
            data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
          ) = format("system:serviceaccount:%s:external-secrets", var.external_secrets_namespace)
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "eso_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name = "secrets-manager-access"
  role = aws_iam_role.eso[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecrets"
      ]
      Resource = "*"
    }]
  })
}
