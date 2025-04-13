variable "subdomain" {
  description = "Subdomain"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1" # Required for ACM with CloudFront
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}
