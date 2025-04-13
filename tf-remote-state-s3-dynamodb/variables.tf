variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "terraform-state-bucket-leosun"
}

variable "dynamodb_table" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
