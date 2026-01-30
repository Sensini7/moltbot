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

## Post-Deployment: Accessing MoltBot

After deployment, follow these steps to access MoltBot.

### Step 1: Get Deployment Details

The gateway token is sensitive and not shown in workflow logs. Get it locally:

```bash
# Set your AWS profile
export AWS_PROFILE=your-profile-name

# Navigate to terraform directory
cd moltbot-terraform

# Initialize with remote backend
terraform init \
  -backend-config="bucket=YOUR_TF_STATE_BUCKET" \
  -backend-config="key=moltbot/dev/terraform.tfstate" \
  -backend-config="region=us-east-1"

# Get all outputs
terraform output

# Get specific outputs
terraform output public_ip
terraform output tailscale_url
terraform output gateway_token
terraform output tailscale_url_with_token
```

### Step 2: Enable Tailscale HTTPS (First-time setup)

Tailscale Serve must be enabled on your tailnet before HTTPS access works.

1. **SSH into the instance:**
   ```bash
   # Get the private key
   terraform output -raw private_key > moltbot-key.pem
   chmod 600 moltbot-key.pem

   # SSH to instance
   ssh -i moltbot-key.pem ubuntu@$(terraform output -raw public_ip)
   ```

2. **Check if Tailscale Serve is enabled:**
   ```bash
   sudo tailscale serve status
   ```

3. **If "No serve config" or serve not enabled**, visit the URL shown in logs:
   ```bash
   sudo tail -50 /var/log/cloud-init-output.log | grep tailscale.com
   ```

   Or go to: **Tailscale Admin Console** → **DNS** → **HTTPS Certificates** → Enable

4. **After enabling, configure serve on the instance:**
   ```bash
   sudo tailscale serve --bg 18789
   ```

5. **Verify serve is active:**
   ```bash
   sudo tailscale serve status
   ```

### Step 3: Access MoltBot

1. Ensure you're connected to your Tailscale network
2. Open the URL from `terraform output tailscale_url_with_token` in your browser:
   ```
   https://ip-10-0-1-xx.your-tailnet.ts.net/?token=your-gateway-token
   ```

## Troubleshooting

### Check MoltBot Gateway Status

```bash
# SSH into instance first, then:

# Check if gateway is running
systemctl --user status moltbot-gateway

# View gateway logs
journalctl --user -u moltbot-gateway -f

# Test gateway locally
curl http://localhost:18789
```

### Check Cloud-Init Installation Logs

```bash
# View installation progress/errors
sudo tail -100 /var/log/cloud-init-output.log

# Check if installation completed
sudo cat /var/log/cloud-init-output.log | grep -i "complete\|error\|warning"
```

### Check Tailscale Status

```bash
# View Tailscale connection status
sudo tailscale status

# Check Tailscale serve configuration
sudo tailscale serve status

# View Tailscale logs
sudo journalctl -u tailscaled -f
```

### Common Issues

#### "This site can't be reached" / ERR_CONNECTION_REFUSED

1. **Check if you're connected to Tailscale** on your local machine
2. **Check if Tailscale Serve is enabled:**
   ```bash
   sudo tailscale serve status
   ```
   If empty, enable it:
   ```bash
   sudo tailscale serve --bg 18789
   ```

#### Gateway Not Running

```bash
# Restart the gateway
systemctl --user restart moltbot-gateway

# Check status
systemctl --user status moltbot-gateway
```

#### Tailscale Serve Not Enabled on Tailnet

Check cloud-init logs for the enable URL:
```bash
sudo grep "tailscale.com/f/serve" /var/log/cloud-init-output.log
```

Visit that URL to enable HTTPS certificates for your tailnet.

#### MoltBot Config Issues

```bash
# View MoltBot config
cat ~/.moltbot/moltbot.json

# Check gateway token in config
cat ~/.moltbot/moltbot.json | grep token
```

### Restart Everything

```bash
# Restart MoltBot gateway
systemctl --user restart moltbot-gateway

# Re-enable Tailscale serve
sudo tailscale serve --bg 18789

# Verify both are working
systemctl --user status moltbot-gateway
sudo tailscale serve status
curl http://localhost:18789
```

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

## Destroying Infrastructure

```bash
# Via GitHub Actions: Manual dispatch → action: destroy

# Or locally:
terraform destroy
```
