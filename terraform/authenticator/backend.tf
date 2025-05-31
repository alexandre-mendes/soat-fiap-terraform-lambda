terraform {
  backend "s3" {
    bucket  = "soat-terraform-state-5dc9264c8c230a834fe2a59b744523fd"
    key     = "lambda-authenticator/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}