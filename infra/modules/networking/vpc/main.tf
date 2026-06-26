# ============================================================================
# modules/networking/vpc — core VPC, DHCP, flow logs
# ============================================================================

locals {
  name = "${var.project}-${var.environment}"

  # Subnet layout derived from the VPC CIDR (assumes a /16):
  #   public      : /24  (NAT GW, ALB ENIs)            -> newbits 8, offset 0
  #   private-app : /20  (EKS worker nodes, many IPs)  -> newbits 4, offset 1..3
  #   private-data: /24  (Aurora, OpenSearch, Redis)   -> newbits 8, offset 100..102
  public_subnets       = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_app_subnets  = [for i in range(3) : cidrsubnet(var.vpc_cidr, 4, i + 1)]
  private_data_subnets = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i + 100)]

  nat_gateway_count = var.single_nat_gateway ? 1 : length(var.availability_zones)

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Module      = "networking/vpc"
    ManagedBy   = "terraform"
  })
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags = merge(local.tags, {
    Name                                            = "${local.name}-vpc"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  })
}

# --- VPC Flow Logs ----------------------------------------------------------
resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc/${local.name}/flow-logs"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = var.kms_key_arn

  tags = local.tags
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${local.name}-vpc-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${local.name}-vpc-flow-logs"
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count                = var.enable_flow_logs ? 1 : 0
  vpc_id               = aws_vpc.this.id
  traffic_type         = "ALL"
  iam_role_arn         = aws_iam_role.flow_logs[0].arn
  log_destination      = aws_cloudwatch_log_group.flow_logs[0].arn
  log_destination_type = "cloud-watch-logs"
  max_aggregation_interval = 60

  tags = merge(local.tags, { Name = "${local.name}-flow-log" })
}

# --- Default SG locked down (no rules => deny all) --------------------------
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${local.name}-default-sg-DO-NOT-USE" })
}