terraform {
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.region
}

# VPC
module "vpc" {
  source = "../../modules/vpc"
  name = "dev"
  vpc_cidr = var.vpc_cidr
  azs = var.azs
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
  tags = var.tags
}

# Security Groups
module "sg" {
  source = "../../modules/security-groups"
  name   = "dev"
  vpc_id = module.vpc.vpc_id
  tags   = var.tags
}

# IAM
module "iam" {
  source = "../../modules/iam"
  name = "dev"
  tags = var.tags
}

# ALB
module "alb" {
  source = "../../modules/alb"
  name = "dev-alb"
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_security_group_id  = module.sg.alb_sg_id
  tags = var.tags
}

# ASG
module "asg" {
  source = "../../modules/asg"
  name = "dev-app"
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  tg_arn = module.alb.target_group_arn
  asg_min = var.asg_min_size
  asg_desired = var.asg_desired_size
  asg_max = var.asg_max_size
  instance_type = var.instance_type
  app_security_group_id  = module.sg.app_sg_id
  instance_profile_name = module.iam.instance_profile_name
  tags = var.tags
}

output "alb_dns" {
  value = module.alb.alb_dns
}
