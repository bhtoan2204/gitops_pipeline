variable "environment" {
  description = "Environment name"
  type        = string
}

variable "public_key" {
  description = "Public key content for SSH access"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
