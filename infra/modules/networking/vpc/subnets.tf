# ============================================================================
# modules/networking/vpc — subnets (public, private-app, private-data)
# ============================================================================

# --- Public subnets (one per AZ) --------------------------------------------
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name                                            = "${local.name}-public-${var.availability_zones[count.index]}"
    Tier                                            = "public"
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  })
}

# --- Private application subnets (EKS worker nodes) -------------------------
resource "aws_subnet" "private_app" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_app_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.tags, {
    Name                                            = "${local.name}-private-app-${var.availability_zones[count.index]}"
    Tier                                            = "private-app"
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "karpenter.sh/discovery"                        = var.eks_cluster_name
  })
}

# --- Private data subnets (Aurora, OpenSearch, Redis) ----------------------
resource "aws_subnet" "private_data" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_data_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.tags, {
    Name = "${local.name}-private-data-${var.availability_zones[count.index]}"
    Tier = "private-data"
  })
}

# --- Subnet groups for data services ---------------------------------------
resource "aws_db_subnet_group" "data" {
  name       = "${local.name}-data"
  subnet_ids = aws_subnet.private_data[*].id
  tags       = merge(local.tags, { Name = "${local.name}-data-subnet-group" })
}

resource "aws_elasticache_subnet_group" "data" {
  name       = "${local.name}-cache"
  subnet_ids = aws_subnet.private_data[*].id
  tags       = merge(local.tags, { Name = "${local.name}-cache-subnet-group" })
}