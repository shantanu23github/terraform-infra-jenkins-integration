# terraform-infra

## Setup Instructions

1. How to install Jenkins on EC2.

https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/

2. AWS Backend Setup
  1. Create an S3 bucket for Terraform remote state storage with versioning enabled:
     ```
     aws s3 mb s3://your-terraform-state-bucket
     aws s3api put-bucket-versioning --bucket your-terraform-state-bucket --versioning-configuration Status=Enabled
     ```

  2. Create a DynamoDB table for state locking:
     ```
     aws dynamodb create-table --table-name terraform-lock-table --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
     ```




       
   





