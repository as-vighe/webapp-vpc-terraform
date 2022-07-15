terraform {

  backend "s3" {
    bucket = "webapp-12345623"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }    
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.8.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}
