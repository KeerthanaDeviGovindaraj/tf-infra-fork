# ─── SNS Topic ───

resource "aws_sns_topic" "user_verification" {
  name = "${var.vpc_name}-user-verification-topic"

  tags = {
    Name = "${var.vpc_name}-user-verification-topic"
  }
}

# ─── SNS Subscription → triggers Lambda ───

resource "aws_sns_topic_subscription" "lambda_sub" {
  topic_arn = aws_sns_topic.user_verification.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.email_lambda.arn
}

# ─── Allow SNS to invoke Lambda ───

resource "aws_lambda_permission" "sns_invoke" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.user_verification.arn
}