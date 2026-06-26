# ============================================================================
# environments/prod — composition root
# ----------------------------------------------------------------------------
# Instantiates every platform module in dependency order. The ordering encodes
# the apply sequence worked out across the module rounds:
#   kms -> observability(sns) -> secrets -> networking -> iam(pass1)
#   -> data-layer -> compute(eks->oidc) -> ai-ml/etl
#   -> iam(pass2 via OIDC+data ARNs) -> edge-security -> security posture
# Terraform resolves most ordering via references; explicit depends_on is used
# only where a dependency isn't expressed through a value.
# ============================================================================

terraform {
  required_version = ">= 1.6.0, < 2.0.0"
}

# Bring in shared backend/provider/version config from the infra root.
# (symlinked or copied; here we re-declare the providers locally.)

# --- Identity / region context ---------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  project     = var.project
  environment = "prod"
  account_id  = data.aws_caller_identity.current.account_id
  region      = var.aws_region

  azs = var.availability_zones

  # Nine microservices mapped to their namespaces (from kubernetes/base/namespaces).
  irsa_service_accounts = {
    chat-gateway        = { namespace = "chat-services", service_account = "chat-gateway" }
    api-service         = { namespace = "chat-services", service_account = "api-service" }
    session-service     = { namespace = "chat-services", service_account = "session-service" }
    agent-orchestrator  = { namespace = "rag-services", service_account = "agent-orchestrator" }
    query-router        = { namespace = "rag-services", service_account = "query-router" }
    retriever-service   = { namespace = "rag-services", service_account = "retriever-service" }
    embedding-service   = { namespace = "rag-services", service_account = "embedding-service" }
    text-to-sql-service = { namespace = "rag-services", service_account = "text-to-sql-service" }
    guardrails-service  = { namespace = "rag-services", service_account = "guardrails-service" }
  }

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "terraform"
    CostCenter  = var.cost_center
  }
}

# ============================================================================
# 1. KMS (foundational — everything encrypts with these keys)
# ============================================================================
module "kms" {
  source = "../../modules/security/kms"

  project              = local.project
  environment          = local.environment
  account_id           = local.account_id
  region               = local.region
  deletion_window_days = 30
  enable_key_rotation  = true
  admin_role_arns      = var.kms_admin_role_arns
  tags                 = local.common_tags
}

# ============================================================================
# 2. Observability — CloudWatch SNS hub (topic needed by many modules)
# ============================================================================
module "cloudwatch" {
  source = "../../modules/observability/cloudwatch"

  project     = local.project
  environment = local.environment
  account_id  = local.account_id
  region      = local.region
  kms_key_arn = module.kms.key_arns["sns"]

  alert_email_addresses = var.alert_email_addresses
  pagerduty_endpoint    = var.pagerduty_endpoint

  # Monitored-resource identifiers are filled by later modules; CloudWatch's
  # alarms are count-guarded so a first apply with nulls is safe. We re-feed
  # these via a second `terraform apply` once resources exist, OR reference
  # them directly (Terraform handles the dependency edges).
  eks_cluster_name           = var.cluster_name
  alb_arn_suffix             = module.alb.alb_arn_suffix
  aurora_cluster_identifier  = module.aurora.cluster_identifier
  redis_replication_group_id = module.redis.replication_group_id
  opensearch_domain_name     = module.opensearch.domain_name
  dynamodb_table_names = [
    module.dynamodb.sessions_table_name,
    module.dynamodb.chat_history_table_name,
  ]
  etl_function_names = values(module.lambda_etl.function_names)

  log_retention_days = var.log_retention_days
  tags               = local.common_tags
}

# ============================================================================
# 3. Secrets Manager (encrypted with the 'secrets' CMK)
# ============================================================================
module "secrets" {
  source = "../../modules/security/secrets-manager"

  project              = local.project
  environment          = local.environment
  kms_key_arn          = module.kms.key_arns["secrets"]
  recovery_window_days = 7
  tags                 = local.common_tags
}

# ============================================================================
# 4. Networking — VPC, endpoints, security groups, Route 53
# ============================================================================
module "vpc" {
  source = "../../modules/networking/vpc"

  project            = local.project
  environment        = local.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.azs
  eks_cluster_name   = var.cluster_name
  single_nat_gateway = false # prod = NAT per AZ
  enable_flow_logs   = true
  kms_key_arn        = module.kms.key_arns["logs"]
  tags               = local.common_tags
}

module "vpc_endpoints" {
  source = "../../modules/networking/vpc-endpoints"

  project                = local.project
  environment            = local.environment
  vpc_id                 = module.vpc.vpc_id
  vpc_cidr               = module.vpc.vpc_cidr
  region                 = local.region
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  gateway_route_table_ids = concat(
    module.vpc.private_app_route_table_ids,
    module.vpc.private_data_route_table_ids,
  )
  tags = local.common_tags
}

module "security_groups" {
  source = "../../modules/networking/security-groups"

  project     = local.project
  environment = local.environment
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = module.vpc.vpc_cidr
  tags        = local.common_tags
}

module "route53" {
  source = "../../modules/networking/route53"

  project                = local.project
  environment            = local.environment
  domain_name            = var.domain_name
  create_public_zone     = var.create_public_zone
  create_private_zone    = true
  vpc_id                 = module.vpc.vpc_id
  cloudfront_domain_name = module.cloudfront.domain_name
  alb_dns_name           = module.alb.alb_dns_name
  alb_zone_id            = module.alb.alb_zone_id
  health_check_fqdn      = var.domain_name
  tags                   = local.common_tags
}

# ============================================================================
# 5. Data layer (S3, DynamoDB, OpenSearch, Redis, Aurora)
# ============================================================================
module "s3" {
  source = "../../modules/data-layer/s3"

  project       = local.project
  environment   = local.environment
  account_id    = local.account_id
  region        = local.region
  kms_key_arn   = module.kms.key_arns["s3"]
  force_destroy = false
  tags          = local.common_tags
}

module "dynamodb" {
  source = "../../modules/data-layer/dynamodb"

  project                = local.project
  environment            = local.environment
  kms_key_arn            = module.kms.key_arns["dynamodb"]
  billing_mode           = "PAY_PER_REQUEST"
  point_in_time_recovery = true
  enable_global_tables   = var.enable_dynamodb_global_tables
  replica_regions        = var.dynamodb_replica_regions
  deletion_protection    = true
  tags                   = local.common_tags
}

module "opensearch" {
  source = "../../modules/data-layer/opensearch"

  project                 = local.project
  environment             = local.environment
  account_id              = local.account_id
  region                  = local.region
  vpc_subnet_ids          = module.vpc.private_data_subnet_ids
  security_group_id       = module.security_groups.opensearch_security_group_id
  kms_key_arn             = module.kms.key_arns["opensearch"]
  instance_type           = var.opensearch_instance_type
  instance_count          = var.opensearch_instance_count
  master_user_secret_arn  = module.secrets.secret_arns["opensearch-master"]
  iam_access_role_arns    = values(module.iam.irsa_role_arns)
  create_service_linked_role = var.create_opensearch_slr
  tags                    = local.common_tags
}

module "redis" {
  source = "../../modules/data-layer/elasticache-redis"

  project                 = local.project
  environment             = local.environment
  subnet_group_name       = module.vpc.elasticache_subnet_group_name
  security_group_id       = module.security_groups.redis_security_group_id
  kms_key_arn             = module.kms.key_arns["redis"]
  node_type               = var.redis_node_type
  num_node_groups         = var.redis_num_shards
  replicas_per_node_group = var.redis_replicas_per_shard
  auth_token_secret_arn   = module.secrets.secret_arns["redis-auth-token"]
  sns_topic_arn           = module.cloudwatch.alerts_topic_arn
  tags                    = local.common_tags
}

module "aurora" {
  source = "../../modules/data-layer/aurora-postgresql"

  project              = local.project
  environment          = local.environment
  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.db_subnet_group_name
  security_group_id    = module.security_groups.aurora_security_group_id
  kms_key_arn          = module.kms.key_arns["rds"]
  secrets_kms_key_arn  = module.kms.key_arns["secrets"]
  use_serverless_v2    = var.aurora_serverless
  serverless_min_acu   = var.aurora_min_acu
  serverless_max_acu   = var.aurora_max_acu
  reader_count         = var.aurora_reader_count
  manage_master_password = true
  enable_rds_proxy     = true
  deletion_protection  = true
  sns_topic_arn        = module.cloudwatch.alerts_topic_arn
  tags                 = local.common_tags
}

# ============================================================================
# 6. Compute — EKS cluster (exports OIDC), node groups, ALB
# ============================================================================
module "eks" {
  source = "../../modules/compute/eks-cluster"

  project                     = local.project
  environment                 = local.environment
  cluster_name                = var.cluster_name
  kubernetes_version          = var.kubernetes_version
  vpc_id                      = module.vpc.vpc_id
  private_app_subnet_ids      = module.vpc.private_app_subnet_ids
  eks_nodes_security_group_id = module.security_groups.eks_nodes_security_group_id
  endpoint_public_access      = var.eks_endpoint_public_access
  endpoint_public_access_cidrs = var.eks_public_access_cidrs
  kms_key_arn                 = module.kms.key_arns["ebs"] # secrets-at-rest CMK
  logs_kms_key_arn            = module.kms.key_arns["logs"]
  ebs_kms_key_arn             = module.kms.key_arns["ebs"]
  cluster_admin_principal_arns = var.cluster_admin_principal_arns
  log_retention_days          = var.log_retention_days
  tags                        = local.common_tags
}

module "node_groups" {
  source = "../../modules/compute/eks-node-groups"

  project                     = local.project
  environment                 = local.environment
  account_id                  = local.account_id
  region                      = local.region
  cluster_name                = module.eks.cluster_name
  cluster_version             = module.eks.cluster_version
  private_app_subnet_ids      = module.vpc.private_app_subnet_ids
  eks_nodes_security_group_id = module.security_groups.eks_nodes_security_group_id
  cluster_security_group_id   = module.eks.cluster_security_group_id
  ebs_kms_key_arn             = module.kms.key_arns["ebs"]
  enable_karpenter            = true
  oidc_provider_arn           = module.eks.oidc_provider_arn
  oidc_provider_url           = module.eks.oidc_provider_url
  system_node_group           = var.system_node_group
  tags                        = local.common_tags
}

module "alb" {
  source = "../../modules/compute/alb"

  project               = local.project
  environment           = local.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  certificate_arn       = var.acm_certificate_arn_regional
  origin_verify_secret  = var.origin_verify_secret
  access_logs_bucket    = module.s3.logs_bucket_id
  enable_deletion_protection = true
  idle_timeout          = 120
  tags                  = local.common_tags
}

# ============================================================================
# 7. IAM — application IRSA roles (now that OIDC + data ARNs exist)
#    Single pass works because the cluster/data modules are referenced
#    directly; Terraform sequences them ahead of this module.
# ============================================================================
module "iam" {
  source = "../../modules/security/iam"

  project               = local.project
  environment           = local.environment
  account_id            = local.account_id
  region                = local.region
  oidc_provider_arn     = module.eks.oidc_provider_arn
  oidc_provider_url     = module.eks.oidc_provider_url
  kms_key_arns          = module.kms.key_arns
  document_bucket_arn   = module.s3.document_bucket_arn
  opensearch_domain_arn = module.opensearch.domain_arn
  dynamodb_table_arns   = module.dynamodb.all_table_arns
  secrets_arns          = module.secrets.all_secret_arns
  irsa_service_accounts = local.irsa_service_accounts
  tags                  = local.common_tags
}

# ============================================================================
# 8. AI/ML — Bedrock (guardrails, KB optional), SageMaker (optional)
# ============================================================================
module "bedrock" {
  source = "../../modules/ai-ml/bedrock"

  project                   = local.project
  environment               = local.environment
  account_id                = local.account_id
  region                    = local.region
  text_model_id             = var.bedrock_text_model_id
  embedding_model_id        = var.bedrock_embedding_model_id
  embedding_dimensions      = var.embedding_dimensions
  enable_invocation_logging = true
  invocation_log_bucket     = module.s3.logs_bucket_id
  logs_kms_key_arn          = module.kms.key_arns["logs"]
  enable_guardrails         = true
  kms_key_arn               = module.kms.key_arns["s3"]
  # Knowledge Base disabled by default — custom ETL is the primary path.
  enable_knowledge_base     = var.enable_bedrock_knowledge_base
  document_bucket_arn       = module.s3.document_bucket_arn
  tags                      = local.common_tags
}

module "sagemaker" {
  source = "../../modules/ai-ml/sagemaker"

  project                    = local.project
  environment                = local.environment
  account_id                 = local.account_id
  region                     = local.region
  enable_endpoint            = var.enable_sagemaker_reranker
  vpc_subnet_ids             = module.vpc.private_app_subnet_ids
  security_group_ids         = [module.security_groups.eks_nodes_security_group_id]
  kms_key_arn                = module.kms.key_arns["ebs"]
  model_image                = var.sagemaker_model_image
  model_artifacts_bucket_arn = module.s3.document_bucket_arn
  tags                       = local.common_tags
}

# ============================================================================
# 9. ETL pipeline — Glue, MWAA, Lambda chain
# ============================================================================
module "lambda_etl" {
  source = "../../modules/etl-pipeline/lambda-etl"

  project              = local.project
  environment          = local.environment
  account_id           = local.account_id
  region               = local.region
  vpc_subnet_ids       = module.vpc.private_app_subnet_ids
  security_group_ids   = [module.security_groups.eks_nodes_security_group_id]
  execution_role_arn   = module.iam.lambda_etl_role_arn
  document_bucket_id   = module.s3.document_bucket_id
  document_bucket_arn  = module.s3.document_bucket_arn
  opensearch_endpoint  = module.opensearch.domain_endpoint
  embedding_model_id   = var.bedrock_embedding_model_id
  embedding_dimensions = var.embedding_dimensions
  kms_key_arn          = module.kms.key_arns["logs"]
  log_retention_days   = var.log_retention_days
  tags                 = local.common_tags
}

module "glue" {
  source = "../../modules/etl-pipeline/glue"

  project            = local.project
  environment        = local.environment
  account_id         = local.account_id
  region             = local.region
  glue_role_arn      = module.iam.glue_role_arn
  document_bucket_id = module.s3.document_bucket_id
  kms_key_arn        = module.kms.key_arns["s3"]
  tags               = local.common_tags
}

module "mwaa" {
  source = "../../modules/etl-pipeline/mwaa"

  project            = local.project
  environment        = local.environment
  account_id         = local.account_id
  region             = local.region
  mwaa_role_arn      = module.iam.mwaa_role_arn
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = slice(module.vpc.private_app_subnet_ids, 0, 2) # MWAA needs exactly 2
  source_bucket_arn  = module.s3.document_bucket_arn
  source_bucket_id   = module.s3.document_bucket_id
  kms_key_arn        = module.kms.key_arns["s3"]
  environment_class  = var.mwaa_environment_class
  max_workers        = var.mwaa_max_workers
  tags               = local.common_tags
}

# ============================================================================
# 10. Edge security — WAF (x2), CloudFront, Shield, API Gateway
# ============================================================================
module "waf_cloudfront" {
  source = "../../modules/edge-security/waf"
  providers = {
    aws = aws.us_east_1 # CLOUDFRONT scope must be us-east-1
  }

  project             = local.project
  environment         = local.environment
  scope               = "CLOUDFRONT"
  rate_limit_per_5min = var.waf_rate_limit
  blocked_countries   = var.waf_blocked_countries
  kms_key_arn         = module.kms.key_arns["logs"]
  tags                = local.common_tags
}

module "waf_regional" {
  source = "../../modules/edge-security/waf"

  project             = local.project
  environment         = local.environment
  scope               = "REGIONAL"
  rate_limit_per_5min = var.waf_rate_limit
  kms_key_arn         = module.kms.key_arns["logs"]
  tags                = local.common_tags
}

module "cloudfront" {
  source = "../../modules/edge-security/cloudfront"

  project                     = local.project
  environment                 = local.environment
  aliases                     = var.cloudfront_aliases
  acm_certificate_arn         = var.acm_certificate_arn_cloudfront # must be us-east-1
  alb_domain_name             = module.alb.alb_dns_name
  web_acl_arn                 = module.waf_cloudfront.web_acl_arn
  logging_bucket_domain       = module.s3.logs_bucket_domain_name
  custom_origin_header_secret = var.origin_verify_secret
  price_class                 = var.cloudfront_price_class
  tags                        = local.common_tags
}

module "shield" {
  source = "../../modules/edge-security/shield-advanced"

  project     = local.project
  environment = local.environment
  protected_resources = var.enable_shield_advanced ? {
    cloudfront = module.cloudfront.distribution_arn
    alb        = module.alb.alb_arn
  } : {}
  enable_proactive_engagement = var.enable_shield_advanced
  emergency_contacts          = var.shield_emergency_contacts
  tags                        = local.common_tags
}

# ============================================================================
# 11. Security posture — GuardDuty, Security Hub
# ============================================================================
module "guardduty" {
  source = "../../modules/security/guardduty"

  project       = local.project
  environment   = local.environment
  sns_topic_arn = module.cloudwatch.alerts_topic_arn
  tags          = local.common_tags
}

module "security_hub" {
  source = "../../modules/security/security-hub"

  project             = local.project
  environment         = local.environment
  region              = local.region
  enable_cis_standard = true
  enable_pci_standard = var.enable_pci_compliance
  tags                = local.common_tags
}

# ============================================================================
# 12. Observability — X-Ray, Backup
# ============================================================================
module "xray" {
  source = "../../modules/observability/xray"

  project       = local.project
  environment   = local.environment
  sampling_rate = var.xray_sampling_rate
  kms_key_arn   = module.kms.key_arns["logs"]
  tags          = local.common_tags
}

module "backup" {
  source = "../../modules/observability/backup"

  project                  = local.project
  environment              = local.environment
  region                   = local.region
  kms_key_arn              = module.kms.key_arns["backup"]
  enable_cross_region_copy = var.enable_backup_cross_region
  dr_region                = var.dr_region
  backup_resource_arns = [
    module.aurora.cluster_arn,
    module.dynamodb.sessions_table_arn,
    module.dynamodb.chat_history_table_arn,
  ]
  enable_vault_lock = var.enable_backup_vault_lock
  sns_topic_arn     = module.cloudwatch.alerts_topic_arn
  tags              = local.common_tags
}