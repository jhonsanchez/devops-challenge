data "archive_file" "ReceiveFillingForm-zip" {
  type = "zip"
  source_dir = "${var.lambdas_input_path}/ReceiveFillingForm"
  output_path = "${var.lambdas_output_path}/ReceiveFillingForm.zip"
}
data "archive_file" "CheckEligibility-zip" {
  type = "zip"
  source_dir = "${var.lambdas_input_path}/CheckEligibility"
  output_path = "${var.lambdas_output_path}/CheckEligibility.zip"
}
data "archive_file" "CheckBureau-zip" {
  type = "zip"
  source_dir = "${var.lambdas_input_path}/CheckBureau"
  output_path = "${var.lambdas_output_path}/CheckBureau.zip"
}
data "archive_file" "CalculateAmountLimit-zip" {
  type = "zip"
  source_dir = "${var.lambdas_input_path}/CalculateAmountLimit"
  output_path = "${var.lambdas_output_path}/CalculateAmountLimit.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "ReceiveFillingForm_role"
  assume_role_policy = <<EOF
{
    "Version" : "2012-10-17",
    "Statement" : [
        {
            "Action" : "sts.AssumeRole",
            "Principal" : {
                "Service" : "lambda.amazonaws.com"
            },
            "Effect" : "Allow",
            "Sid" : ""
        }
    ]
}    
  EOF
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole","arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"]
}

resource "aws_lambda_function" "ReceiveFillingForm_lambda" {
  filename = "${var.lambdas_output_path}/ReceiveFillingForm.zip"
  function_name = "ReceiveFillingForm"
  role = aws_iam_role.lambda_role.arn
  handler = "ReceiveFillingForm.lambda_handler"
  source_code_hash = data.archive_file.ReceiveFillingForm-zip.output_base64sha256
  runtime = "python3.8"
}
resource "aws_lambda_function" "CheckEligibility_lambda" {
  filename = "${var.lambdas_output_path}/CheckEligibility_lambda.zip"
  function_name = "CheckEligibility_lambda"
  role = aws_iam_role.lambda_role.arn
  handler = "CheckEligibility.lambda_handler"
  source_code_hash = data.archive_file.CheckEligibility-zip.output_base64sha256
  runtime = "python3.8"
}
resource "aws_lambda_function" "CheckBureau_lambda" {
  filename = "${var.lambdas_output_path}/CheckBureau.zip"
  function_name = "CheckBureau"
  role = aws_iam_role.lambda_role.arn
  handler = "CheckBureau.lambda_handler"
  source_code_hash = data.archive_file.CheckBureau-zip.output_base64sha256
  runtime = "python3.8"
}
resource "aws_sqs_queue" "check_egilibility_queue" {
  name                    = "check_egilibility_queue"
  sqs_managed_sse_enabled = true
}
resource "aws_sqs_queue" "check_bureau_queue" {
  name                    = "check_bureau_queue"
  sqs_managed_sse_enabled = true
}
resource "aws_sqs_queue" "calculate_amount_limit_queue" {
  name                    = "calculate_amount_limit_queue"
  sqs_managed_sse_enabled = true
}
resource "aws_s3_bucket" "react_app_bucket" {
  bucket = var.bucket_prefix
}
resource "aws_s3_bucket_acl" "react_app_bucket_acl" {
  bucket = aws_s3_bucket.react_app_bucket.id
  acl    = "private"
}
resource "aws_s3_bucket_website_configuration" "react_app_bucket_website_configuration" {
  bucket = aws_s3_bucket.react_app_bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "process/"
    }
    redirect {
      replace_key_prefix_with = "processing/"
    }
  }
}

resource "aws_wafv2_web_acl" "bank_app" {
  name        = "managed-rule-bank_app"
  description = "bank app managed rule."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rule-1"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        excluded_rule {
          name = "SizeRestrictions_QUERYSTRING"
        }

        excluded_rule {
          name = "NoUserAgent_HEADER"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-metric"
      sampled_requests_enabled   = false
    }
  }

  tags = {
    Name = "WAF_RULE"
    Cost_Center = "XXSS"
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-metric"
    sampled_requests_enabled   = false
  }
}
