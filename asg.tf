# Security group that will be assigned to DeSo nodes that allows alb_http_sg to communicate on port 80 & 443 TCP.
module "asg_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = var.name
  description = "A security group that exposes DeSo Docker Compose deployment ports to ALB."
  vpc_id      = var.aws_vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = var.deso_frontend_port
      to_port                  = var.deso_frontend_port
      protocol                 = 6
      description              = "http-${var.deso_frontend_port}-tcp"
      source_security_group_id = module.alb_https_sg.security_group_id
    },
    {
      from_port                = local.deso_frontend_healthcheck_port
      to_port                  = local.deso_frontend_healthcheck_port
      protocol                 = 6
      description              = "http-${local.deso_frontend_healthcheck_port}-tcp"
      source_security_group_id = module.alb_https_sg.security_group_id
    },
    {
      from_port                = var.deso_backend_port
      to_port                  = var.deso_backend_port
      protocol                 = 6
      description              = "http-${var.deso_backend_port}-tcp"
      source_security_group_id = module.alb_https_sg.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 3

  computed_ingress_with_cidr_blocks = [
    {
      rule        = "ssh-tcp"
      cidr_blocks = "${var.ssh_access_ip_address}/32"
    }
  ]

  number_of_computed_ingress_with_cidr_blocks = 1

  egress_rules = ["all-all"]

  tags = var.tags
}

# Getting the AWS AMI ID of the Amazon Linux 2 instance, running on arm64 architecture that can have an EBS volume.
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# AWS EC2 Instance Launch Template that defines that we want an instance with above AMI, of specific type and 400GB volume.
# Auto scaling group for our DeSo node. We can run one, we can run many.
# Auto scaling group will start deso nodes as spot instances to save costs.
# TODO: Confirm that DeSo can run on spots.
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 4.0"

  # Autoscaling group
  name                   = var.name
  description            = "Launch Template for DeSo nodes"
  create_lt              = true
  update_default_version = true

  image_id                 = data.aws_ami.amazon_linux_2.id
  instance_type            = "t3.2xlarge"
  ebs_optimized            = true
  enable_monitoring        = true
  vpc_zone_identifier      = var.aws_vpc_public_subnets
  service_linked_role_arn  = aws_iam_service_linked_role.autoscaling.arn
  iam_instance_profile_arn = aws_iam_instance_profile.ssm.arn
  user_data_base64         = base64encode(local.user_data)

  target_group_arns           = module.alb.target_group_arns
  associate_public_ip_address = true

  min_size                  = var.min_nodes_count
  max_size                  = var.max_nodes_count
  desired_capacity          = var.desired_nodes_count
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"

  key_name = var.aws_key_pair_key_name

  use_mixed_instances_policy = true
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "capacity-optimized"
    }
  }

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 400
        volume_type           = "gp2"
      }
    }
  ]

  network_interfaces = [
    {
      delete_on_termination       = true
      description                 = "eth0"
      device_index                = 0
      security_groups             = [module.asg_sg.security_group_id]
      associate_public_ip_address = true
    }
  ]

  initial_lifecycle_hooks = [
    {
      name                  = local.startup_lifecycle_hook_name
      default_result        = "CONTINUE"
      heartbeat_timeout     = 180
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
      notification_metadata = jsonencode({ "hello" = "world" })
    }
  ]

  tags_as_map = var.tags
}