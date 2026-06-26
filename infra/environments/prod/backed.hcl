# ============================================================================
# environments/prod — backend partial config
# Used as: terraform init -backend-config=backend.hcl
# ============================================================================
bucket         = "enterprise-ai-rag-tfstate-111122223333"
key            = "prod/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "enterprise-ai-rag-tflock"
encrypt        = true