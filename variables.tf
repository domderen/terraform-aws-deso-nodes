variable "name" {
  type        = string
  description = "Name under which DeSo Nodes will be deployed. This will also be a beginning of a URL under which DeSo will be deployed. DeSo nodes will be exposed at https://$(var.name).$(var.deso_public_hosted_zone)."
  default     = "deso-nodes"
}

variable "ssh_access_ip_address" {
  type        = string
  description = "IP Address allowed to SSH into DeSo nodes."
}

variable "aws_key_pair_key_name" {
  type        = string
  description = "Name of the AWS Key Pair that will be used to SSH into DeSo nodes."
}

variable "aws_vpc_id" {
  type        = string
  description = "ID of the VPC in which DeSo nodes should be created."
}

variable "aws_vpc_public_subnets" {
  type        = list(string)
  description = "List of public subnets in which DeSo nodes should be created."
}

variable "deso_frontend_port" {
  type        = number
  description = "Port number at which DeSo Frontend is exposed on the EC2 Node."
  default     = 8080
}

variable "deso_backend_port" {
  type        = number
  description = "Port number at which DeSo Backend is exposed on the EC2 Node."
  default     = 17001
}

variable "deso_public_hosted_zone" {
  type        = string
  description = "AWS Route53 hosted zone name at which DeSo DNS endpoints will be added. DeSo nodes will be exposed at https://$(var.name).$(var.deso_public_hosted_zone)."
}

variable "deso_backend_docker_image" {
  type        = string
  description = "Docker image that will be used to run the DeSo backend."
  default     = "docker.io/desoprotocol/backend:stable"
}

variable "deso_frontend_docker_image" {
  type        = string
  description = "Docker image that will be used to run the DeSo backend."
  default     = "docker.io/desoprotocol/frontend:stable"
}

variable "miner_public_keys" {
  type        = string
  description = "DeSo MINER_PUBLIC_KEYS env var."
  default     = ""
}

variable "admin_public_keys" {
  type        = string
  description = "DeSo ADMIN_PUBLIC_KEYS env var."
  default     = ""
}

variable "super_admin_public_keys" {
  type        = string
  description = "DeSo SUPER_ADMIN_PUBLIC_KEYS env var."
  default     = ""
}

variable "twilio_account_sid" {
  type        = string
  description = "DeSo TWILIO_ACCOUNT_SID env var."
  default     = ""
  sensitive   = true
}

variable "twilio_auth_token" {
  type        = string
  description = "DeSo TWILIO_AUTH_TOKEN env var."
  default     = ""
  sensitive   = true
}

variable "twilio_verify_service_id" {
  type        = string
  description = "DeSo TWILIO_VERIFY_SERVICE_ID env var."
  default     = ""
  sensitive   = true
}

variable "support_email" {
  type        = string
  description = "DeSo SUPPORT_EMAIL env var."
}

variable "min_nodes_count" {
  type        = number
  description = "Minimal number of nodes that should be ran."
  default     = 0
}

variable "max_nodes_count" {
  type        = number
  description = "Maximal number of nodes that should be ran."
  default     = 1
}

variable "desired_nodes_count" {
  type        = number
  description = "Desired number of nodes that should be ran."
  default     = 1
}

variable "tags" {
  type        = map(string)
  description = "Tags that will be added to AWS resources."
  default     = {}
}