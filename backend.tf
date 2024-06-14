terraform {
  backend "s3" {
    bucket = "terraform-bucket-1306"
    key = "expense-terraform/dev/state"
    region = "us-east-1"
  }
}