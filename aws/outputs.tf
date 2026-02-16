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

# AWS Instance Outputs
output "aws_instance_id" {
  description = "ID of the AWS EC2 instance"
  value       = aws_instance.webapp.id
}

output "aws_instance_public_ip" {
  description = "Public IP of the AWS EC2 instance"
  value       = aws_instance.webapp.public_ip
}

output "aws_ami_id" {
  description = "AMI ID used"
  value       = data.aws_ami.webapp.id
}

output "aws_application_url" {
  description = "Application URL"
  value       = "http://${aws_instance.webapp.public_ip}:${var.application_port}"
}

output "aws_metadata_endpoint" {
  description = "Metadata endpoint URL"
  value       = "http://${aws_instance.webapp.public_ip}:${var.application_port}/v1/metadata"
}