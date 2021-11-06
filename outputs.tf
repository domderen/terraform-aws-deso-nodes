output "alb_dns" {
  description = "DNS Name at which AWS ALB is exposed."
  value       = module.alb.lb_dns_name
}

output "deso_dns" {
  description = "DNS Name as which DeSo nodes are exposed."
  value       = local.deso_dns
}