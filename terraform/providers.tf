# terraform/providers.tf
provider "aws" {
  region = "ap-south-1" # Ensure this matches your aws configure region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}