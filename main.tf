provider "aws" {
  region = "us-east-1"
}

module "user_service" {
  source = "./lambda_user.tf"
}
