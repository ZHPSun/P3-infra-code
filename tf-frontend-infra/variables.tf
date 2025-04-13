variable "subdomain" {
  description = "Subdomain"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1" # Required for ACM with CloudFront
}

variable "content_version" {
  description = "Version string for static content"
  type        = string
  default     = "v1"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "hosted_zone_id" {
  description = "Hosted zone ID"
  type        = string
}
