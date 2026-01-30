terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# Generate SSH key
resource "tls_private_key" "moltbot_ssh" {
  algorithm = "ED25519"
}

# Generate gateway token
resource "random_id" "gateway_token" {
  byte_length = 24
}

# VPC
resource "aws_vpc" "moltbot" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "moltbot" {
  vpc_id = aws_vpc.moltbot.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# Subnet
resource "aws_subnet" "moltbot" {
  vpc_id                  = aws_vpc.moltbot.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-subnet"
  })
}

# Route Table
resource "aws_route_table" "moltbot" {
  vpc_id = aws_vpc.moltbot.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.moltbot.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rt"
  })
}

resource "aws_route_table_association" "moltbot" {
  subnet_id      = aws_subnet.moltbot.id
  route_table_id = aws_route_table.moltbot.id
}

# Security Group
resource "aws_security_group" "moltbot" {
  name        = "${local.name_prefix}-sg"
  description = "Security group for MoltBot instance"
  vpc_id      = aws_vpc.moltbot.id

  # SSH access (fallback - use Tailscale SSH when possible)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic (required for API calls, updates, Tailscale)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sg"
  })
}

# Key Pair
resource "aws_key_pair" "moltbot" {
  key_name   = "${local.name_prefix}-key"
  public_key = tls_private_key.moltbot_ssh.public_key_openssh

  tags = local.common_tags
}

# Get latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User data script
locals {
  user_data = templatefile("${path.module}/user-data.sh.tpl", {
    anthropic_api_key  = var.anthropic_api_key
    tailscale_auth_key = var.tailscale_auth_key
    gateway_port       = var.gateway_port
    browser_port       = var.browser_port
    gateway_token      = random_id.gateway_token.hex
  })
}

# EC2 Instance
resource "aws_instance" "moltbot" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.moltbot.id
  vpc_security_group_ids      = [aws_security_group.moltbot.id]
  key_name                    = aws_key_pair.moltbot.key_name
  user_data                   = local.user_data
  user_data_replace_on_change = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-instance"
  })

  lifecycle {
    create_before_destroy = true
  }
}
