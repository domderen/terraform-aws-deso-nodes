# Creates a certificate that is used to secure HTTPS traffic to ALB.
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  domain_name = local.deso_dns
  zone_id     = data.aws_route53_zone.this.id
}

# Security group allowing access to the ALB on HTTP 80.
module "alb_http_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "~> 4.0"

  name        = "${var.name}-alb-http"
  vpc_id      = var.aws_vpc_id
  description = "Security group for ${var.name} allowing access for procotol HTTP on port 80."

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = var.tags
}

# Security group allowing access to the ALB on HTTPS 443.
module "alb_https_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/https-443"
  version = "~> 4.0"

  name        = "${var.name}-alb-https"
  vpc_id      = var.aws_vpc_id
  description = "Security group for ${var.name} allowing access for protocol HTTPS on port 443."

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = var.tags
}

# ALB that will be exposing DeSo nodes.
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = var.name

  vpc_id          = var.aws_vpc_id
  subnets         = var.aws_vpc_public_subnets
  security_groups = [module.alb_http_sg.security_group_id, module.alb_https_sg.security_group_id]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      target_group_index = 0
      certificate_arn    = module.acm.acm_certificate_arn
    }
  ]

  https_listener_rules = [
    {
      https_listener_index = 0
      priority             = 1

      actions = [
        {
          type               = "forward"
          target_group_index = 0
        }
      ]

      conditions = [{
        host_headers  = [local.deso_dns]
        path_patterns = ["/api/*"]
      }]
    },
    {
      https_listener_index = 0
      priority             = 2

      actions = [
        {
          type               = "forward"
          target_group_index = 1
        }
      ]

      conditions = [{
        host_headers  = [local.deso_dns]
        path_patterns = ["/*"]
      }]
    }
  ]

  target_groups = [
    {
      name                 = "${var.name}-backend"
      backend_protocol     = "HTTP"
      backend_port         = var.deso_backend_port
      target_type          = "instance"
      deregistration_delay = 30
    },
    {
      name                 = "${var.name}-frontend"
      backend_protocol     = "HTTP"
      backend_port         = var.deso_frontend_port
      target_type          = "instance"
      deregistration_delay = 30
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/health-check"
        port                = local.deso_frontend_healthcheck_port
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  ]

  tags = var.tags
}