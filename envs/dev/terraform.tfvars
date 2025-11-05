region = "us-east-1"

vpc_cidr = "10.0.0.0/16"
public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
azs = ["us-east-1a", "us-east-1b"]

asg_min_size     = 1
asg_desired_size = 2
asg_max_size     = 4
instance_type    = "t3.micro"

tags = {
  Project     = "python-crud"
  Environment = "dev"
}
