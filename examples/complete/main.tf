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
