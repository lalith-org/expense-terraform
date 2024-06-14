terraform {
  backend "s3" {
    bucket = "terraform-bucket-1306"
    key = "expense-terraform/dev/tools"
    region = "us-east-1"
  }
}