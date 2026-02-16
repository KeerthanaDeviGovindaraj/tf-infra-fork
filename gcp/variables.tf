variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-east1"
}

variable "vpc_name" {
  description = "Name for VPC network"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
}

# Application Configuration
variable "application_port" {
  description = "Port on which the application runs"
  type        = number
  default     = 8080
}

# GCP Instance Configuration
variable "gcp_machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-medium"
  
  validation {
    condition     = contains(["e2-micro", "e2-small", "e2-medium"], var.gcp_machine_type)
    error_message = "Machine type must be e2-micro, e2-small, or e2-medium."
  }
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
  default     = "us-east1-b"
}