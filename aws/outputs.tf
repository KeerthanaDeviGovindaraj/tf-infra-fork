# ─── VPC Outputs ───

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "availability_zones" {
  description = "Availability zones used"
  value       = data.aws_availability_zones.available.names
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}
output "app_url" {
  description = "Application URL via domain name"
  value       = "http://${var.domain_name}:8080"
}

output "sns_topic_arn" {
  description = "ARN of the SNS user verification topic"
  value       = aws_sns_topic.user_verification.arn
}

output "lambda_function_arn" {
  description = "ARN of the email verification Lambda function"
  value       = aws_lambda_function.email_lambda.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB email tracking table"
  value       = aws_dynamodb_table.email_tracking.name
}
