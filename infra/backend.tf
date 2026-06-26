# ============================================================================
# infrastructure — remote state backend
# ----------------------------------------------------------------------------
# Partial configuration: the bucket/key/dynamodb_table values are supplied
# per environment via `-backend-config=backend.hcl` (see environments/<env>/).
# This keeps a single module definition while isolating state per env.
# ============================================================================

terraform {
  backend "s3" {
    encrypt = true
    # bucket         = "..."   # provided via backend.hcl
    # key            = "..."   # provided via backend.hcl
    # region         = "..."   # provided via backend.hcl
    # dynamodb_table = "..."   # provided via backend.hcl
  }
}