variable "name" {
  type        = string
  description = "Name under which DeSo Nodes will be deployed. This will also be a beginning of a URL under which DeSo will be deployed. DeSo nodes will be exposed at https://$(var.name).$(var.deso_public_hosted_zone)."
  default     = "deso-nodes"
}

variable "deso_public_hosted_zone" {
  type        = string
  description = "AWS Route53 hosted zone name at which DeSo DNS endpoints will be added. DeSo nodes will be exposed at https://$(var.name).$(var.deso_public_hosted_zone)/."
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