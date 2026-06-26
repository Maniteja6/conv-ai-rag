# ============================================================================
# modules/networking/vpc — outputs (consumed by every downstream module)
# ============================================================================

output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC CIDR block."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB, NAT)."
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs (EKS nodes)."
  value       = aws_subnet.private_app[*].id
}

output "private_data_subnet_ids" {
  description = "Private data subnet IDs (Aurora, OpenSearch, Redis)."
  value       = aws_subnet.private_data[*].id
}

output "private_app_route_table_ids" {
  description = "Route table IDs for private-app subnets (for gateway endpoints)."
  value       = aws_route_table.private_app[*].id
}

output "private_data_route_table_ids" {
  description = "Route table IDs for private-data subnets (for gateway endpoints)."
  value       = aws_route_table.private_data[*].id
}

output "db_subnet_group_name" {
  description = "RDS/Aurora DB subnet group name."
  value       = aws_db_subnet_group.data.name
}

output "elasticache_subnet_group_name" {
  description = "ElastiCache subnet group name."
  value       = aws_elasticache_subnet_group.data.name
}

output "nat_gateway_public_ips" {
  description = "Public EIPs of the NAT gateways (for allowlisting egress)."
  value       = aws_eip.nat[*].public_ip
}

output "availability_zones" {
  description = "AZs the VPC spans."
  value       = var.availability_zones
}