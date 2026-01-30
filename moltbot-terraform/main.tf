terraform {
  required_version = ">= 1.5.0"

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

  # Backend configuration is in backend.tf
  # Initialized via -backend-config flags in GitHub Actions
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "moltbot"
      ManagedBy   = "terraform"
      Repository  = "moltbot-terraform"
    }
  }
}

module "moltbot" {
  source = "./modules/moltbot"

  aws_region         = var.aws_region
  instance_type      = var.instance_type
  anthropic_api_key  = var.anthropic_api_key
  tailscale_auth_key = var.tailscale_auth_key
  tailnet_dns_name   = var.tailnet_dns_name
  gateway_port       = var.gateway_port
  browser_port       = var.browser_port
  environment        = var.environment
  project_name       = var.project_name
  root_volume_size   = var.root_volume_size
  vpc_cidr           = var.vpc_cidr
  subnet_cidr        = var.subnet_cidr
  tags               = var.tags
}
