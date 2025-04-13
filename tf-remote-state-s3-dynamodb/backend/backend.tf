terraform {
  backend "s3" {
    bucket         = "YOUR_BUCKET_NAME" # Replace with your bucket name
    key            = "<your-module>/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
