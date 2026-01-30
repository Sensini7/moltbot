#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo "======================================"
echo "  MoltBot Installation Starting"
echo "======================================"

# System updates
echo "[1/8] Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Docker
echo "[2/8] Installing Docker..."
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# Install NVM and Node.js for ubuntu user
echo "[3/8] Installing Node.js via NVM..."
sudo -u ubuntu bash << 'UBUNTU_SCRIPT'
set -e
cd ~

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Install Node.js 22
nvm install 22
nvm use 22
nvm alias default 22

# Install MoltBot
echo "[4/8] Installing MoltBot..."
npm install -g moltbot@beta

# Add NVM to bashrc
if ! grep -q 'NVM_DIR' ~/.bashrc; then
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> ~/.bashrc
fi
UBUNTU_SCRIPT

# Set environment variables
echo "[5/8] Configuring environment..."
echo 'export ANTHROPIC_API_KEY="${anthropic_api_key}"' >> /home/ubuntu/.bashrc

# Install and configure Tailscale
echo "[6/8] Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --authkey="${tailscale_auth_key}" --ssh || echo "WARNING: Tailscale setup failed"

# Enable systemd linger for user services
loginctl enable-linger ubuntu
systemctl start user@1000.service || true

# Run MoltBot onboarding
echo "[7/8] Running MoltBot onboarding..."
sudo -H -u ubuntu ANTHROPIC_API_KEY="${anthropic_api_key}" GATEWAY_PORT="${gateway_port}" bash -c '
export HOME=/home/ubuntu
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

moltbot onboard --non-interactive --accept-risk \
    --mode local \
    --auth-choice apiKey \
    --gateway-port $GATEWAY_PORT \
    --gateway-bind loopback \
    --skip-daemon \
    --skip-skills || echo "WARNING: Onboarding failed"
'

# Install daemon
echo "[8/8] Installing MoltBot daemon..."
sudo -H -u ubuntu XDG_RUNTIME_DIR=/run/user/1000 bash -c '
export HOME=/home/ubuntu
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

moltbot daemon install || echo "WARNING: Daemon install failed"
'

# Configure gateway
echo "Configuring gateway..."
sudo -H -u ubuntu GATEWAY_TOKEN="${gateway_token}" python3 << 'PYTHON_SCRIPT'
import json
import os

config_path = "/home/ubuntu/.moltbot/moltbot.json"
try:
    with open(config_path) as f:
        config = json.load(f)

    config["gateway"]["trustedProxies"] = ["127.0.0.1"]
    config["gateway"]["controlUi"] = {
        "enabled": True,
        "allowInsecureAuth": True
    }
    config["gateway"]["auth"] = {
        "mode": "token",
        "token": os.environ["GATEWAY_TOKEN"]
    }

    with open(config_path, "w") as f:
        json.dump(config, f, indent=2)
    print("Gateway configuration updated successfully")
except Exception as e:
    print(f"WARNING: Failed to configure gateway: {e}")
PYTHON_SCRIPT

# Enable Tailscale HTTPS proxy
echo "Enabling Tailscale HTTPS proxy..."
tailscale serve --bg ${gateway_port} || echo "WARNING: tailscale serve failed"

echo ""
echo "======================================"
echo "  MoltBot Installation Complete!"
echo "======================================"
echo ""
echo "Gateway Port: ${gateway_port}"
echo "Browser Port: ${browser_port}"
echo ""
