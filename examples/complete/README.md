# Complete Example

An example presenting how to deploy DeSo Blockchain. This application will be available at https://${local.name}.${var.deso_public_hosted_zone}/ after deployment.

This example assumes that you have an existing Route53 Hosted Zone which name you provide as `var.deso_public_hosted_zone`.

This example creates two additional resources:

- AWS EC2 Key Pair that can be used to SSH into DeSo nodes,
- AWS VPC where your DeSo nodes will exist.

## How to SSH

```bash
terraform output --raw ssh_private_key_pem > key.pem
chmod 600 key.pem
# You can find the node ip address in AWS EC2 console.
ssh -i key.pem ec2-user@${DESO_NODE_PUBLIC_IP}
```

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
| <a name="input_deso_public_hosted_zone"></a> [deso\_public\_hosted\_zone](#input\_deso\_public\_hosted\_zone) | AWS Route53 hosted zone name at which DeSo DNS endpoints will be added. DeSo nodes will be exposed at https://$(var.name).$(var.deso_public_hosted_zone)/. | `string` | n/a | yes |
| <a name="input_miner_public_keys"></a> [miner\_public\_keys](#input\_miner\_public\_keys) | DeSo MINER\_PUBLIC\_KEYS env var. | `string` | `""` | no |
| <a name="input_super_admin_public_keys"></a> [super\_admin\_public\_keys](#input\_super\_admin\_public\_keys) | DeSo SUPER\_ADMIN\_PUBLIC\_KEYS env var. | `string` | `""` | no |
| <a name="input_support_email"></a> [support\_email](#input\_support\_email) | DeSo SUPPORT\_EMAIL env var. | `string` | n/a | yes |
| <a name="input_twilio_account_sid"></a> [twilio\_account\_sid](#input\_twilio\_account\_sid) | DeSo TWILIO\_ACCOUNT\_SID env var. | `string` | `""` | no |
| <a name="input_twilio_auth_token"></a> [twilio\_auth\_token](#input\_twilio\_auth\_token) | DeSo TWILIO\_AUTH\_TOKEN env var. | `string` | `""` | no |
| <a name="input_twilio_verify_service_id"></a> [twilio\_verify\_service\_id](#input\_twilio\_verify\_service\_id) | DeSo TWILIO\_VERIFY\_SERVICE\_ID env var. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_dns"></a> [alb\_dns](#output\_alb\_dns) | DNS Name at which AWS ALB is exposed. |
| <a name="output_deso_dns"></a> [deso\_dns](#output\_deso\_dns) | DNS Name DeSo node is exposed. |
| <a name="output_ip_address_allowed_to_ssh"></a> [ip\_address\_allowed\_to\_ssh](#output\_ip\_address\_allowed\_to\_ssh) | IP address that is allowed to SSH access DeSo nodes. |
| <a name="output_ssh_private_key_pem"></a> [ssh\_private\_key\_pem](#output\_ssh\_private\_key\_pem) | Private SSH key that can be used to connect to the DeSo nodes. |

## Resources

| Name | Type |
|------|------|
| [tls_private_key.this](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [http_http.ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
<!-- END_TF_DOCS -->