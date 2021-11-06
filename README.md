# Terraform AWS DeSo blockchain nodes

Create your own [DeSo Blockchain](https://www.deso.org/) feed in minutes.

Everything that you need to run your own [DeSo Blockchain](https://www.deso.org/) nodes on AWS. This module is intended as a simple and easy initialization of your own nodes, that are automatically exposed to the world on a DNS hostname that you specify.

- Configure DeSo deployment to your liking via terraform variables,
- You can specify your own forks of DeSo Backend & Frontend docker images to run your own custom deployment;

This terraform module deploys [DeSo Blockchain](https://www.deso.org/) nodes as an AWS Auto Scaling Group, and exposes them via an AWS Application Load Balancer as a DNS hostname in AWS Route53. In addition it creates AWS IAM Role & AWS IAM Instance Profile with permissions to manage autoscaling of the AWS ASG, and with ability to put logs to AWS CloudWatch Logs. Finally it creates 2 AWS CloudWatch Log Groups:

- `${var.name}/backend`
- `${var.name}/frontend`

That will contain logs for the three containers that are deployed on each DeSo node.

<!-- BEGIN_TF_DOCS -->
## Example

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {}

# Get IP address of the user executing this terraform module.
data "http" "ip" {
  url = "https://ifconfig.me"
}

locals {
  name       = "deso-complete"
  aws_region = "us-east-1"
}

module "deso_nodes" {
  source = "../../"

  name = local.name

  # Allow SSH access to IP from which this terraform module is executed.
  ssh_access_ip_address = data.http.ip.body
  # Create new keypair and allow SSH access to this key.
  aws_key_pair_key_name = module.key_pair.key_pair_key_name
  # Create new VPC and create DeSo nodes in this VPC.
  aws_vpc_id             = module.vpc.vpc_id
  aws_vpc_public_subnets = module.vpc.public_subnets
  # Set current DeSo nodes counts.
  min_nodes_count     = 0
  max_nodes_count     = 1
  desired_nodes_count = 1
  # Tags that will be added to AWS resources.
  tags = {
    Project          = local.name
    TerraformManaged = "true"
  }

  # DeSo specific configuration.
  deso_backend_docker_image  = "docker.io/desoprotocol/backend:stable"
  deso_frontend_docker_image = "docker.io/desoprotocol/frontend:stable"
  deso_frontend_port         = 8080
  deso_backend_port          = 17001
  deso_public_hosted_zone    = var.deso_public_hosted_zone
  miner_public_keys          = var.miner_public_keys
  admin_public_keys          = var.admin_public_keys
  super_admin_public_keys    = var.super_admin_public_keys
  support_email              = var.support_email
  twilio_account_sid         = var.twilio_account_sid
  twilio_auth_token          = var.twilio_auth_token
  twilio_verify_service_id   = var.twilio_verify_service_id
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_public_keys"></a> [admin\_public\_keys](#input\_admin\_public\_keys) | DeSo ADMIN\_PUBLIC\_KEYS env var. | `string` | `""` | no |
| <a name="input_aws_key_pair_key_name"></a> [aws\_key\_pair\_key\_name](#input\_aws\_key\_pair\_key\_name) | Name of the AWS Key Pair that will be used to SSH into DeSo nodes. | `string` | n/a | yes |
| <a name="input_aws_vpc_id"></a> [aws\_vpc\_id](#input\_aws\_vpc\_id) | ID of the VPC in which DeSo nodes should be created. | `string` | n/a | yes |
| <a name="input_aws_vpc_public_subnets"></a> [aws\_vpc\_public\_subnets](#input\_aws\_vpc\_public\_subnets) | List of public subnets in which DeSo nodes should be created. | `list(string)` | n/a | yes |
| <a name="input_desired_nodes_count"></a> [desired\_nodes\_count](#input\_desired\_nodes\_count) | Desired number of nodes that should be ran. | `number` | `1` | no |
| <a name="input_deso_backend_docker_image"></a> [deso\_backend\_docker\_image](#input\_deso\_backend\_docker\_image) | Docker image that will be used to run the DeSo backend. | `string` | `"docker.io/desoprotocol/backend:stable"` | no |
| <a name="input_deso_backend_port"></a> [deso\_backend\_port](#input\_deso\_backend\_port) | Port number at which DeSo Backend is exposed on the EC2 Node. | `number` | `17001` | no |
| <a name="input_deso_frontend_docker_image"></a> [deso\_frontend\_docker\_image](#input\_deso\_frontend\_docker\_image) | Docker image that will be used to run the DeSo backend. | `string` | `"docker.io/desoprotocol/frontend:stable"` | no |
| <a name="input_deso_frontend_port"></a> [deso\_frontend\_port](#input\_deso\_frontend\_port) | Port number at which DeSo Frontend is exposed on the EC2 Node. | `number` | `8080` | no |
| <a name="input_deso_public_hosted_zone"></a> [deso\_public\_hosted\_zone](#input\_deso\_public\_hosted\_zone) | AWS Route53 hosted zone name at which DeSo DNS endpoints will be added. DeSo nodes will be exposed at https://$(var.name).$(var.deso_public_hosted_zone). | `string` | n/a | yes |
| <a name="input_max_nodes_count"></a> [max\_nodes\_count](#input\_max\_nodes\_count) | Maximal number of nodes that should be ran. | `number` | `1` | no |
| <a name="input_min_nodes_count"></a> [min\_nodes\_count](#input\_min\_nodes\_count) | Minimal number of nodes that should be ran. | `number` | `0` | no |
| <a name="input_miner_public_keys"></a> [miner\_public\_keys](#input\_miner\_public\_keys) | DeSo MINER\_PUBLIC\_KEYS env var. | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | Name under which DeSo Nodes will be deployed. This will also be a beginning of a URL under which DeSo will be deployed. DeSo nodes will be exposed at https://$(var.name).$(var.deso_public_hosted_zone). | `string` | `"deso-nodes"` | no |
| <a name="input_ssh_access_ip_address"></a> [ssh\_access\_ip\_address](#input\_ssh\_access\_ip\_address) | IP Address allowed to SSH into DeSo nodes. | `string` | n/a | yes |
| <a name="input_super_admin_public_keys"></a> [super\_admin\_public\_keys](#input\_super\_admin\_public\_keys) | DeSo SUPER\_ADMIN\_PUBLIC\_KEYS env var. | `string` | `""` | no |
| <a name="input_support_email"></a> [support\_email](#input\_support\_email) | DeSo SUPPORT\_EMAIL env var. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags that will be added to AWS resources. | `map(string)` | `{}` | no |
| <a name="input_twilio_account_sid"></a> [twilio\_account\_sid](#input\_twilio\_account\_sid) | DeSo TWILIO\_ACCOUNT\_SID env var. | `string` | `""` | no |
| <a name="input_twilio_auth_token"></a> [twilio\_auth\_token](#input\_twilio\_auth\_token) | DeSo TWILIO\_AUTH\_TOKEN env var. | `string` | `""` | no |
| <a name="input_twilio_verify_service_id"></a> [twilio\_verify\_service\_id](#input\_twilio\_verify\_service\_id) | DeSo TWILIO\_VERIFY\_SERVICE\_ID env var. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_dns"></a> [alb\_dns](#output\_alb\_dns) | DNS Name at which AWS ALB is exposed. |
| <a name="output_deso_dns"></a> [deso\_dns](#output\_deso\_dns) | DNS Name as which DeSo nodes are exposed. |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_instance_profile.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_service_linked_role.autoscaling](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_route53_record.deso_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_ami.amazon_linux_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy.CloudWatchAgentServerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
<!-- END_TF_DOCS -->
