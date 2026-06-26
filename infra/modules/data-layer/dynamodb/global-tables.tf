# ============================================================================
# modules/data-layer/dynamodb — global tables note
# ----------------------------------------------------------------------------
# With provider AWS v5, multi-region replication is expressed inline via the
# `replica` blocks on aws_dynamodb_table (see tables.tf), gated by
# var.enable_global_tables. The standalone aws_dynamodb_global_table resource
# is the legacy (v2017.11.29) API and is intentionally NOT used here.
#
# To enable multi-region DR:
#   enable_global_tables = true
#   replica_regions      = ["us-west-2"]
# and ensure a CMK with a matching alias exists in each replica region.
#
# This keeps the default deployment single-region ("Regional", per the
# architecture diagram) while making DR a one-flag change.
# ============================================================================