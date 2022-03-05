terraform {
  required_version = "= 1.1.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.74.3"
    }
  }

  backend "s3" {
    bucket = "kwsh-terraform-state"
    region = "ap-northeast-1"
    key = "privatelink-nlb/target-env/terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      Project     = "privatelink-nlb/target-env",
      Environment = "dev",
      Terraform   = true,
    }
  }
}
