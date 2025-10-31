terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

# Register the domain in Route53 Domains (must use us-east-1)
resource "aws_route53domains_registered_domain" "this" {
  count       = var.register_domain ? 1 : 0
  provider    = aws.us_east_1
  domain_name = var.domain_name
  auto_renew  = var.auto_renew

  admin_contact {
    first_name        = var.contact_admin.first_name
    last_name         = var.contact_admin.last_name
    contact_type      = var.contact_admin.contact_type
    organization_name = try(var.contact_admin.organization, null)
    address_line_1    = var.contact_admin.address_line_1
    address_line_2    = try(var.contact_admin.address_line_2, null)
    city              = var.contact_admin.city
    state             = var.contact_admin.state
    country_code      = var.contact_admin.country_code
    zip_code          = var.contact_admin.zip_code
    phone_number      = var.contact_admin.phone_number
    email             = var.contact_admin.email
    fax               = try(var.contact_admin.fax, null)
  }

  registrant_contact {
    first_name        = var.contact_registrant.first_name
    last_name         = var.contact_registrant.last_name
    contact_type      = var.contact_registrant.contact_type
    organization_name = try(var.contact_registrant.organization, null)
    address_line_1    = var.contact_registrant.address_line_1
    address_line_2    = try(var.contact_registrant.address_line_2, null)
    city              = var.contact_registrant.city
    state             = var.contact_registrant.state
    country_code      = var.contact_registrant.country_code
    zip_code          = var.contact_registrant.zip_code
    phone_number      = var.contact_registrant.phone_number
    email             = var.contact_registrant.email
    fax               = try(var.contact_registrant.fax, null)
  }

  tech_contact {
    first_name        = var.contact_tech.first_name
    last_name         = var.contact_tech.last_name
    contact_type      = var.contact_tech.contact_type
    organization_name = try(var.contact_tech.organization, null)
    address_line_1    = var.contact_tech.address_line_1
    address_line_2    = try(var.contact_tech.address_line_2, null)
    city              = var.contact_tech.city
    state             = var.contact_tech.state
    country_code      = var.contact_tech.country_code
    zip_code          = var.contact_tech.zip_code
    phone_number      = var.contact_tech.phone_number
    email             = var.contact_tech.email
    fax               = try(var.contact_tech.fax, null)
  }

  admin_privacy      = var.privacy_protect
  registrant_privacy = var.privacy_protect
  tech_privacy       = var.privacy_protect

  # billing_contact is not supported by this resource in Terraform AWS provider

  tags = var.tags
}

# Create a public hosted zone for the domain
resource "aws_route53_zone" "primary" {
  name = var.domain_name
  tags = var.tags
}


