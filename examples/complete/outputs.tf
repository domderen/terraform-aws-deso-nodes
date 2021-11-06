output "ssh_private_key_pem" {
  description = "Private SSH key that can be used to connect to the DeSo nodes."
  value       = tls_private_key.this.private_key_pem
  sensitive   = true
}

output "ip_address_allowed_to_ssh" {
  description = "IP address that is allowed to SSH access DeSo nodes."
  value       = data.http.ip.body
}

output "alb_dns" {
  description = "DNS Name at which AWS ALB is exposed."
  value       = module.deso_nodes.alb_dns
}

output "deso_dns" {
  description = "DNS Name DeSo node is exposed."
  value       = module.deso_nodes.deso_dns
}