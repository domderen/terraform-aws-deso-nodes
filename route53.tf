
data "aws_route53_zone" "this" {
  name = var.deso_public_hosted_zone
}

resource "aws_route53_record" "deso_record" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.deso_dns
  type    = "A"

  alias {
    name                   = module.alb.lb_dns_name
    zone_id                = module.alb.lb_zone_id
    evaluate_target_health = true
  }
}