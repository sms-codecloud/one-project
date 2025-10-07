terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~> 6.10.0"
    }
  }
  backend "local" {
    path = "D:\\Git-CodeCloud\\terraform_states\\one-project-infra\\terraform.tfstate"
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project = "one-project"
    }
  }
}