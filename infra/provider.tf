terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { 
        source = "hashicorp/aws", 
        version = "~> 6.10.0" 
    }
  }
  backend "s3" {
    bucket         = "arj-bootcamp"
    key            = "one-project/state/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
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