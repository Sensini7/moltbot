# Remote Backend Configuration
# Backend values are passed via -backend-config during terraform init
# This allows for dynamic configuration via GitHub Actions secrets

terraform {
  backend "s3" {
    # These values are configured via CLI during init:
    # -backend-config="bucket=<bucket-name>"
    # -backend-config="key=<state-file-path>"
    # -backend-config="region=<region>"
    # -backend-config="dynamodb_table=<lock-table>" (optional)

    encrypt = true
  }
}
