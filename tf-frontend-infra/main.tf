

# S3 bucket for static content
resource "aws_s3_bucket" "static_site" {
  bucket = replace(var.subdomain, ".", "-")
}

resource "aws_s3_bucket_public_access_block" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload index.html and index.js
resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.static_site.id
  key    = "index.html"
  source = "../goexpertproject/goexpertfrontendtest/index.html" # 本地 front 文件夹中的 index.html
  # acl          = "public-read"
  content_type = "text/html"
}

resource "aws_s3_object" "form_js" {
  bucket = aws_s3_bucket.static_site.id
  key    = "form.js"
  source = "../goexpertproject/goexpertfrontendtest/form.js" # 本地 front 文件夹中的 index.js
  # acl          = "public-read"
  content_type = "application/javascript"
}

# # Create new ACM Certificate
# resource "aws_acm_certificate" "cert" {
#   # Request certificate for both specific and wildcard domains
#   domain_name               = var.subdomain
#   subject_alternative_names = ["*.${var.subdomain}"]
#   validation_method         = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# Quote the certificate already issued
data "aws_acm_certificate" "cert" {
  domain      = var.subdomain
  most_recent = true
  statuses    = ["ISSUED"]
}


# CloudFront origin access control
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "OAC ${var.subdomain}"
  description                       = "Origin Access Control for Static Website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# S3 bucket policy document
data "aws_iam_policy_document" "static_site" {
  statement {
    sid       = "AllowCloudFrontServicePrincipal"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_site.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

# S3 bucket policy
resource "aws_s3_bucket_policy" "static_site" {
  bucket = aws_s3_bucket.static_site.id
  policy = data.aws_iam_policy_document.static_site.json
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.subdomain]

  origin {
    domain_name              = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = "S3Origin"
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# CloudFront DNS record (CNAME)
resource "aws_route53_record" "cdn_alias" {
  zone_id = var.hosted_zone_id
  name    = var.subdomain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
