# ─── DynamoDB Table for Email Tracking ───

resource "aws_dynamodb_table" "email_tracking" {
  name         = "${var.vpc_name}-email-tracking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "email"

  attribute {
    name = "email"
    type = "S"
  }

  tags = {
    Name = "${var.vpc_name}-email-tracking"
  }
}

# ─── Lambda Function ───

resource "aws_lambda_function" "email_lambda" {
  function_name = "${var.vpc_name}-email-verification-lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 30
  filename      = var.lambda_zip_path

  environment {
    variables = {
      SES_FROM_EMAIL = var.ses_from_email
      APP_DOMAIN     = var.app_domain
      DYNAMODB_TABLE = aws_dynamodb_table.email_tracking.name
    }
  }

  tags = {
    Name = "${var.vpc_name}-email-verification-lambda"
  }
}