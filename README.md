# MoltBot Terraform Deployment

Infrastructure as Code for deploying MoltBot on AWS EC2 with Tailscale secure access.

## Project Structure

### Module Structure (`moltbot-terraform/modules/moltbot/`)

| File | Description |
|------|-------------|
| `variables.tf` | Module input variables |
| `main.tf` | VPC, EC2, security groups |
| `outputs.tf` | Module outputs |
| `user-data.sh.tpl` | EC2 bootstrap script |

### Root Configuration (`moltbot-terraform/`)

| File | Description |
|------|-------------|
| `main.tf` | Root module calling moltbot module |
| `variables.tf` | Root variables |
| `outputs.tf` | Root outputs |
| `backend.tf` | S3 backend (configured via CLI) |
| `terraform.tfvars` | Local config (gitignored) |
| `terraform.tfvars.example` | Example config |
| `.gitignore` | Git ignore rules |

### GitHub Actions (`.github/workflows/`)

| File | Description |
|------|-------------|
| `terraform.yml` | CI/CD workflow |

## Required GitHub Secrets

Add these secrets to your repository:

| Secret | Description |
|--------|-------------|
| `AWS_ROLE_ARN` | IAM role ARN for OIDC authentication |
| `AWS_REGION` | AWS region (e.g., `us-east-1`) |
| `TF_STATE_BUCKET` | Your existing S3 bucket for state |
| `ANTHROPIC_API_KEY` | Anthropic API key |
| `TAILSCALE_AUTH_KEY` | Tailscale auth key |
| `TAILNET_DNS_NAME` | Your tailnet DNS (e.g., `tailxxxxx.ts.net`) |

## Workflow Usage

- **PR**: Automatically runs validate + plan
- **Push to main**: Automatically applies changes
- **Manual dispatch**: Choose plan/apply/destroy + environment

## Local Development

```bash
cd moltbot-terraform

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
# vim terraform.tfvars

# Initialize with backend
terraform init \
  -backend-config="bucket=your-bucket" \
  -backend-config="key=moltbot/dev/terraform.tfstate" \
  -backend-config="region=us-east-1"

# Plan
terraform plan

# Apply
terraform apply

# Get access URL
terraform output tailscale_url_with_token
```
