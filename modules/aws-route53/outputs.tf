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

output "aws_access_key_id" {
  value = aws_iam_access_key.this.id

  description = <<-EOT
    The AWS access key ID for the created IAM user.
    This is used to authenticate AWS API requests.
    Make sure to store this value securely.
  EOT
}

output "aws_secret_access_key" {
  value = aws_iam_access_key.this.secret

  description = <<-EOT
    The AWS secret access key associated with the access key ID.
    This is sensitive information required for authentication with AWS.
    Keep this value secure and avoid hardcoding it in version control or logs.
  EOT
}

output "route53_zone_id" {
  value = data.aws_route53_zone.this.zone_id

  description = <<-EOT
    The ID of the Route53 hosted zone that is being managed.
    This value is used to associate DNS records with the correct hosted zone.
  EOT
}
