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