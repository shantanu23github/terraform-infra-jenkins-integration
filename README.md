# terraform-infra

## Setup Instructions

### **1. Install Jenkins on EC2**

Refer to the official Jenkins AWS installation guide:  
🔗 https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/

---

### **2. Configure AWS Backend for Terraform Remote State**

Create an S3 bucket for Terraform state storage:

```bash
aws s3 mb s3://your-terraform-state-bucket
aws s3api put-bucket-versioning \
--bucket your-terraform-state-bucket \
--versioning-configuration Status=Enabled
```   
Create a DynamoDB table for state locking:
```bash
                      
        aws dynamodb create-table \
        --table-name terraform-lock-table \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
 
```
3. Terraform Install on ec2.
```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com \
$(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update  
sudo apt-get install terraform  
```
# Module Documentation


### VPC Module   
The VPC module provisions a complete Virtual Private Cloud (VPC) setup including public and private subnets, Internet Gateway, NAT Gateway, and route tables to allow both public internet access for public subnets and secure outbound internet access from private subnets.   

**Resources Created**:  

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
  
  **aws_iam_role_policy_attachment.ssm**: Attach AmazonSSMManagedInstanceCore for SSM.
  
  **aws_iam_role_policy_attachment.cwagent**: Attach CloudWatchAgentServerPolicy for monitoring.
  
  **aws_iam_role_policy_attachment.s3_read**: Attach AmazonS3ReadOnlyAccess for S3 read-only permissions.
  
  **aws_iam_instance_profile.ec2_profile**: Instance profile to associate role with EC2 instances.  

**Input Variables**:
| Name | Type        | Description                     | 
| ---- | ----------- | ------------------------------- | 
| name | string      | Base name for IAM resources     | 
| tags | map(string) | Tags to attach to all resources |  


**Outputs**:
| Name                  | Description                          |
| --------------------- | ------------------------------------ |
| instance_profile_name | Name of the created instance profile |
| instance_role_name    | Name of the created IAM role         |  


### Security Group Module
This module creates security groups to control network traffic for the Application Load Balancer (ALB) and application EC2 instances within a VPC. It defines ingress and egress rules aligning with best practices to ensure secure and controlled traffic flow.  

**Resources Created**:  

**aws_security_group.alb_sg**: Security group for the ALB permitting HTTP and HTTPS ingress from anywhere.

**aws_security_group.app_sg**: Security group for application EC2 instances permitting inbound HTTP from ALB security group and SSH from internal network.  


**Input Variables**:  
| Name   | Type        | Description                                   |
| ------ | ----------- | --------------------------------------------- |
| name   | string      | Base name for security group names            |
| vpc_id | string      | VPC where the security groups will be created |
| tags   | map(string) | Tags to apply to created security groups      |  

**Outputs**:    

| Name      | Description                                        |
| --------- | -------------------------------------------------- |
| alb_sg_id | ID of the Application Load Balancer Security Group |
| app_sg_id | ID of the Application servers Security Group       |  

### ASG module
This module creates an EC2 Auto Scaling Group (ASG) using a launch template that defines the EC2 instance configuration. It automatically scales the number of instances across private subnets and integrates with an existing Elastic Load Balancer target group to distribute traffic.  

**Resources Created**:   
**aws_launch_template.lt**: EC2 launch template with instance details including AMI, instance type, IAM instance profile, security groups, and user data.

**aws_autoscaling_group.asg**: Auto Scaling Group managing EC2 instances across private subnets with scaling bounds and ELB health checks.  


**Input Variables**:  
| Name                  | Type         | Description                                            |
| --------------------- | ------------ | ------------------------------------------------------ |
| name                  | string       | Base name prefix for created resources                 |
| vpc_id                | string       | VPC ID (not directly used but helpful for referencing) |
| private_subnet_ids    | list(string) | List of private subnet IDs for ASG deployment          |
| tg_arn                | string       | ARN of the ELB target group to attach the ASG          |
| asg_min               | number       | Minimum number of instances in the ASG                 |
| asg_desired           | number       | Desired number of instances in the ASG                 |
| asg_max               | number       | Maximum number of instances in the ASG                 |
| instance_type         | string       | EC2 instance type for launch template                  |
| tags                  | map(string)  | Tags to apply to the launch template and instances     |
| app_security_group_id | string       | Security Group ID to associate with launched instances |
| instance_profile_name | string       | IAM instance profile name for EC2 instances            |

**Outputs**:  
| Name     | Description                    |
| -------- | ------------------------------ |
| asg_name | Name of the Auto Scaling Group |  


### ALB Module

This module creates an AWS Application Load Balancer (ALB) along with its target group and listener to distribute incoming HTTP traffic to registered EC2 instances.  

**Resources Created**:  
**aws_lb.this**: The Application Load Balancer resource.

**aws_lb_target_group.app_tg**: Target group for routing traffic to EC2 instances.

**aws_lb_listener.http**: HTTP listener forwarding requests to the target group.

**Input Variables**:

| Name                  | Type         | Description                                        |
| --------------------- | ------------ | -------------------------------------------------- |
| name                  | string       | Base name for ALB and related resources            |
| vpc_id                | string       | VPC ID where ALB and target group are deployed     |
| public_subnet_ids     | list(string) | List of public subnet IDs where ALB will be placed |
| alb_security_group_id | string       | Security Group ID for the ALB                      |
| tags                  | map(string)  | Tags to apply to ALB resources                     |

**Outputs**:

| Name             | Description                                  |
| ---------------- | -------------------------------------------- |
| alb_arn          | ARN of the created Application Load Balancer |
| alb_dns          | DNS name of the Application Load Balancer    |
| target_group_arn | ARN of the ALB target group                  |


# Architecture  

### VPC Network Foundation

Creates an Amazon Virtual Private Cloud (VPC) with CIDR block segmentation.

Defines both public and private subnets distributed across multiple Availability Zones (AZs) for high availability and fault tolerance.

Configures Internet Gateway and NAT Gateway:

        Internet Gateway enables internet access to public subnets.
        
        NAT Gateway allows instances in private subnets to initiate outbound internet connections securely.

Custom route tables route traffic appropriately to IGW for public subnets and NAT Gateway for private subnets.

Tags and naming conventions organize resources for clarity and management.

### Security Groups for Traffic Control

Security Group for Application Load Balancer (ALB) allows inbound HTTP (80) and HTTPS (443) traffic from anywhere (internet).

Security Group for Application Servers allows inbound HTTP only from ALB SG and SSH only from trusted CIDR (e.g., internal network).

Outbound traffic from security groups is fully open (allow all), common for controlled environments.

This separation ensures layered security minimizing exposure of backend EC2 instances.

### IAM Roles for Instance Permissions

IAM role with an EC2 assume-role policy lets EC2 instances authenticate securely.

Attaches managed policies like AmazonSSMManagedInstanceCore (for AWS Systems Manager), CloudWatchAgentServerPolicy (for monitoring), and AmazonS3ReadOnlyAccess (for secure S3 reads).

IAM Instance Profile bundles the role to be associated during EC2 instance launch.

### Auto Scaling Group with Launch Template

Defines a launch template specifying:

Latest Amazon Linux 2 AMI dynamically resolved via SSM parameter store.

Instance type as defined by user inputs.

IAM instance profile for permissions.

Security groups applying the network controls.

User data script encoded to bootstrap instances.

Creates an Auto Scaling Group to manage EC2 instance scaling automatically across private subnets.

Integrates with an ALB target group for load distribution.

Health checks via ELB ensure only healthy instances serve traffic.

Set minimum, desired, and maximum scaling bounds for capacity management.

### Application Load Balancer (ALB) Setup

Internet-facing ALB distributes incoming HTTP traffic to the application instances.

Deployed across public subnets ensuring availability.

Associated with the ALB Security Group controlling inbound traffic.

Target group configured to check instance health and forward traffic to instance targets.

HTTP listener on port 80 forwards requests to target group.

### Terraform Best Practices Employed

Modular design, breaking infrastructure into reusable, logical modules (VPC, IAM, SG, ASG, ALB).

Clear separation of variables, outputs, and minimal use of defaults for flexibility.

Remote state management is intended (per your deliverables), typically utilizing S3 and DynamoDB for state file storage and state locking (not explicitly shown but recommended).

Use of dynamic data sources (e.g., AWS SSM Parameter for fetching AMI) to avoid hard-coding and support upgrades.

Well-tagged resources and meaningful naming conventions for manageability.

Jenkins integration (as per your original goal) can automate entire provisioning lifecycle with plan, approval gates, and apply steps.


       
   





