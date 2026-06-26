# ============================================================================
# modules/networking/vpc-endpoints
#   Interface endpoints : Bedrock (runtime+agent), Secrets Manager, ECR
#                          (api+dkr), CloudWatch Logs, STS, Bedrock Runtime
#   Gateway endpoints    : S3, DynamoDB
# Keeps service-to-AWS traffic on the AWS backbone (no NAT egress, no
# public internet) — matches the PrivateLink block in the architecture.
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "networking/vpc-endpoints"
    ManagedBy   = "terraform"
  })

  # Interface endpoints to create: service short-name => AWS service suffix
  interface_endpoints = {
    bedrock         = "bedrock"
    bedrock_runtime = "bedrock-runtime"
    bedrock_agent   = "bedrock-agent-runtime"
    secretsmanager  = "secretsmanager"
    ecr_api         = "ecr.api"
    ecr_dkr         = "ecr.dkr"
    logs            = "logs"
    sts             = "sts"
    kms             = "kms"
    sqs             = "sqs"
  }
}

# --- Security group for interface endpoints --------------------------------
resource "aws_security_group" "endpoints" {
  name        = "${local.name}-vpce-sg"
  description = "Allow HTTPS from within the VPC to interface endpoints."
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-vpce-sg" })
}

# --- Interface endpoints ----------------------------------------------------
resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_app_subnet_ids
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = merge(local.tags, { Name = "${local.name}-vpce-${each.key}" })
}

# --- S3 gateway endpoint ----------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.gateway_route_table_ids

  tags = merge(local.tags, { Name = "${local.name}-vpce-s3" })
}

# --- DynamoDB gateway endpoint ---------------------------------------------
resource "aws_vpc_endpoint" "dynamodb" {
  count             = var.enable_dynamodb_endpoint ? 1 : 0
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.gateway_route_table_ids

  tags = merge(local.tags, { Name = "${local.name}-vpce-dynamodb" })
}