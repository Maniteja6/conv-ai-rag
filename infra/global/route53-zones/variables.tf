variable "aws_region" { type = string, default = "us-east-1" }
variable "root_domain" { type = string }
variable "env_delegations" {
  description = "Subdomain => list of NS records for per-env zone delegation."
  type        = map(list(string))
  default     = {}
}