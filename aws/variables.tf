variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
}

variable "vpc_name" {
  description = "Name prefix for VPC resources"
  type        = string

  validation {
    condition     = length(var.vpc_name) > 0 && length(var.vpc_name) <= 50
    error_message = "VPC name must be between 1 and 50 characters."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (must have exactly 3)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 3
    error_message = "Must provide exactly 3 public subnet CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (must have exactly 3)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 3
    error_message = "Must provide exactly 3 private subnet CIDR blocks."
  }
}

variable "application_port" {
  description = "Port on which the application runs"
  type        = number
  default     = 8080
}

variable "aws_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium"], var.aws_instance_type)
    error_message = "Instance type must be t2.micro, t2.small, or t2.medium."
  }
}

# ─── RDS Configuration ───

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.4"
}

variable "db_parameter_group_family" {
  description = "DB parameter group family"
  type        = string
  default     = "postgres16"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "csye6225"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "csye6225"
}

# ─── Route53 / DNS ───

variable "domain_name" {
  description = "The Route53 hosted zone domain name for this environment"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for the environment (different for DEV and DEMO)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN. Leave empty for DEV (auto-created). Set for DEMO (imported cert)."
  type        = string
  default     = ""
}

variable "ses_from_email" {
  description = "Verified SES email address used to send verification emails"
  type        = string
}

variable "app_domain" {
  description = "Domain of the web application (used in verification email link)"
  type        = string
}

variable "lambda_zip_path" {
  description = "Path to the Lambda function ZIP file"
  type        = string
  default     = "./lambda.zip"
}