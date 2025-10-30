variable "domain_name" {
  description = "The domain name to register and create a hosted zone for"
  type        = string
}

variable "auto_renew" {
  description = "Enable auto-renewal for the domain"
  type        = bool
  default     = true
}

variable "privacy_protect" {
  description = "Enable privacy protection for admin/registrant/tech contacts"
  type        = bool
  default     = true
}

variable "register_domain" {
  description = "Whether to manage an already-registered domain in this AWS account"
  type        = bool
  default     = false
}

variable "contact_admin" {
  description = "Admin contact information"
  type = object({
    first_name      = string
    last_name       = string
    contact_type    = string
    organization    = optional(string)
    address_line_1  = string
    address_line_2  = optional(string)
    city            = string
    state           = string
    country_code    = string # e.g. VN, US
    zip_code        = string
    phone_number    = string
    email           = string
    fax             = optional(string)
  })
}

variable "contact_registrant" {
  description = "Registrant contact information"
  type = object({
    first_name      = string
    last_name       = string
    contact_type    = string
    organization    = optional(string)
    address_line_1  = string
    address_line_2  = optional(string)
    city            = string
    state           = string
    country_code    = string
    zip_code        = string
    phone_number    = string
    email           = string
    fax             = optional(string)
  })
}

variable "contact_tech" {
  description = "Technical contact information"
  type = object({
    first_name      = string
    last_name       = string
    contact_type    = string
    organization    = optional(string)
    address_line_1  = string
    address_line_2  = optional(string)
    city            = string
    state           = string
    country_code    = string
    zip_code        = string
    phone_number    = string
    email           = string
    fax             = optional(string)
  })
}

variable "tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}


