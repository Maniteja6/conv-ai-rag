# ============================================================================
# global/route53-zones — apex public zone (delegated to per-env subdomains)
# Applied once; per-env modules create their own subdomain records.
# ============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.60" }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags { tags = { ManagedBy = "terraform", Scope = "global" } }
}

resource "aws_route53_zone" "apex" {
  name    = var.root_domain
  comment = "Apex zone for ${var.root_domain} (managed globally)."
}

# Delegate env subdomains (dev./staging.) to per-env NS if split-zone is used.
resource "aws_route53_record" "env_delegation" {
  for_each = var.env_delegations
  zone_id  = aws_route53_zone.apex.zone_id
  name     = "${each.key}.${var.root_domain}"
  type     = "NS"
  ttl      = 172800
  records  = each.value
}

output "apex_zone_id" { value = aws_route53_zone.apex.zone_id }
output "apex_name_servers" { value = aws_route53_zone.apex.name_servers }