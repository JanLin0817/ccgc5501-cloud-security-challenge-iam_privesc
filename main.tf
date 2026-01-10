#############################################
# IAM Privilege Escalation by EC2 - Custom Scenario
# Attack Path: User Data Modification
#############################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "iam_privesc_by_ec2"
      Environment = "lab"
      Scenario    = var.scenario_id
    }
  }
}

#############################################
# Variables
#############################################

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "scenario_id" {
  description = "Unique identifier for this scenario instance"
  type        = string
  default     = "cgid"
}

variable "whitelisted_cidr" {
  description = "CIDR block to whitelist for access"
  type        = string
  default     = "0.0.0.0/0"
}

#############################################
# Random suffix for unique naming
#############################################

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  scenario_name = "iam-privesc-ec2-${random_string.suffix.result}"
}

#############################################
# Data Sources
#############################################

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# Get latest Amazon Linux 2 AMI (8GB default root volume)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
