provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket       = "terraform-vpc-eks-statefile-bucket-gokul"
    key          = "eks/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  private_subnet_cidr= var.private_subnet_cidr
  public_az          = var.public_az
  private_az         = var.private_az
}

module "dynamodb" {
  source     = "./modules/dynamodb"
  table_name = var.table_name
}

module "eks" {
  source       = "./modules/eks"
  cluster_name = var.cluster_name
  subnet_ids   = [module.vpc.public_subnet_id, module.vpc.private_subnet_id]
}
