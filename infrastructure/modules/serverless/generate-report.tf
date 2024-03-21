# CUR report needs a separate provider with the region "us-east-1" because CUR report
# is currently available only for this region
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cur_report_definition
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# default S3 bucket policy required for CUR report
# https://docs.aws.amazon.com/cur/latest/userguide/cur-s3.html
resource "aws_s3_bucket_policy" "cur_bucket_policy" {
  bucket = var.s3_xc3_bucket.bucket
  policy = jsonencode({
    Version = "2008-10-17",
    Id      = "Policy1335892530063",
    Statement = [
      {
        Sid    = "Stmt1335892150622",
        Effect = "Allow",
        Principal = {
          Service = "billingreports.amazonaws.com"
        },
        Action = [
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy"
        ],
        Resource = var.s3_xc3_bucket.arn,
        Condition = {
          StringLike = {
            "aws:SourceArn" = "arn:aws:cur:us-east-1:${data.aws_caller_identity.current.account_id}:definition/*"
          }
        }
      },
      {
        Sid    = "Stmt1335892526596",
        Effect = "Allow",
        Principal = {
          Service = "billingreports.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${var.s3_xc3_bucket.arn}/*",
        Condition = {
          StringLike = {
            "aws:SourceArn" = "arn:aws:cur:us-east-1:${data.aws_caller_identity.current.account_id}:definition/*"
          }
        }
      }
    ]
  })
}

# CUR to get cost of individual resources
resource "aws_cur_report_definition" "cur_report_definition" {
  provider = aws.us_east_1

  report_name                = "xc3report"
  time_unit                  = "DAILY"
  format                     = "textORcsv"
  compression                = "ZIP"
  additional_schema_elements = ["RESOURCES"]
  s3_bucket                  = var.s3_xc3_bucket.bucket
  s3_region                  = var.region
  s3_prefix                  = "report"
  additional_artifacts       = ["REDSHIFT", "QUICKSIGHT"]
  report_versioning          = "OVERWRITE_REPORT"
}
