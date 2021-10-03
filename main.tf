# Terraform configuration

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc_ec2" {
  source      = "./vpc_ec2"
}

module "cicd" {
  source      = "./cicd"
}