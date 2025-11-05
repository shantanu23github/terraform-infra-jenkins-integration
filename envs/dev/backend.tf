terraform {
  backend "s3" {
    bucket         = "myapp-tf-state-s3-backend-bucket"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}
