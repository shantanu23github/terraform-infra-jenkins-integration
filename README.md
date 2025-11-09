# terraform-infra

## Setup Instructions

1. How to install Jenkins on EC2.

https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/

2. AWS Backend Setup                  
Create an S3 bucket for Terraform remote state storage with versioning enabled:                  
        aws s3 mb s3://your-terraform-state-bucket
        aws s3api put-bucket-versioning --bucket your-terraform-state-bucket --versioning-configuration Status=Enabled
   
Create a DynamoDB table for state locking:                       
aws dynamodb create-table --table-name terraform-lock-table --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5  

3. Terraform Install on ec2.
        sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
        wget -O- https://apt.releases.hashicorp.com/gpg | \
        gpg --dearmor | \
        sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
        gpg --no-default-keyring \
        --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
        --fingerprint
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
           
        sudo apt update
        sudo apt-get install terraform
         

# Module Documentation


### VPC Module  
The VPC module provisions a complete Virtual Private Cloud (VPC) setup including public and private subnets, Internet Gateway, NAT Gateway, and route tables to allow both public internet access for public subnets and secure outbound internet access from private subnets.  

Resources Created:  

**aws_vpc.this**: The main VPC with defined CIDR block.

**aws_internet_gateway.this**: Internet Gateway attached to the VPC.

**aws_subnet.public**: List of public subnets with public IP mapping enabled.

**aws_subnet.private**: List of private subnets.

**aws_eip.nat**: Elastic IP for the NAT Gateway.

**aws_nat_gateway.this**: NAT Gateway deployed in first public subnet.

**aws_route_table.public**: Route table for public subnets with a default route to the Internet Gateway.

**aws_route_table.private**: Route table for private subnets with a default route to the NAT Gateway.

Route table associations for each subnet accordingly.  

**Input Variables**:  

| Name            | Type         | Description                                         |
| --------------- | ------------ | --------------------------------------------------- | 
| name            | string       | Base name to tag AWS resources                      |
| vpc_cidr        | string       | CIDR block for the VPC                              |
| azs             | list(string) | List of AWS availability zones for subnet placement |
| public_subnets  | list(string) | List of CIDRs for public subnets                    |
| private_subnets | list(string) | List of CIDRs for private subnets                   |
| tags            | map(string)  | Map of tags to apply to all created resources       |  


**outputs**:  

| Name               | Description                                |
| ------------------ | ------------------------------------------ |
| vpc_id             | The ID of the created VPC                  |
| public_subnet_ids  | List of IDs of the created public subnets  |
| private_subnet_ids | List of IDs of the created private subnets |
| nat_id             | The ID of the created NAT Gateway          |


### IAM Module

This module creates an IAM role for EC2 instances with an assume role policy that allows EC2 service to assume the role. It attaches essential managed policies to enable common AWS service integrations and creates an instance profile to associate with EC2 instances.  

**Resources Created**  

        **aws_iam_role.ec2_role**: IAM role with assume role trust policy for EC2 service.

       ** aws_iam_role_policy_attachment.ssm**: Attach AmazonSSMManagedInstanceCore for SSM.
        
        aws_iam_role_policy_attachment.cwagent: Attach CloudWatchAgentServerPolicy for monitoring.
        
        aws_iam_role_policy_attachment.s3_read: Attach AmazonS3ReadOnlyAccess for S3 read-only permissions.
        
        aws_iam_instance_profile.ec2_profile: Instance profile to associate role with EC2 instances.

### Security Group Module


### ASG module


### ALB Module
        



       
   





