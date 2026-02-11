# AWS Infrastructure

This directory contains Terraform configurations for AWS networking infrastructure.

## Architecture

The infrastructure creates:

- **VPC**: Virtual Private Cloud with DNS support
- **Public Subnets**: Internet-accessible subnets with Internet Gateway
- **Private Subnets**: Internal subnets with NAT Gateway for outbound access
- **NAT Gateways**: One per availability zone for high availability
- **Route Tables**: Separate routing for public and private subnets
- **VPN Gateway**: Optional VPN connectivity

## Prerequisites

1. AWS CLI installed and configured
2. AWS credentials with appropriate permissions
3. Terraform >= 1.0

## Setup

### 1. Configure AWS Credentials

```bash
aws configure
```

Or set environment variables:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 2. Create terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
aws_region  = "us-east-1"
project_name = "myproject"
environment  = "dev"
owner        = "yourname"
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Apply Configuration

```bash
terraform apply
```

## Resource Naming Convention

All resources follow the pattern: `{project_name}-{environment}-{owner}-{resource_type}`

Example: `myproject-dev-john-vpc`

## Outputs

After applying, Terraform will output:

- VPC ID and CIDR
- Subnet IDs (public and private)
- NAT Gateway IDs and public IPs
- Route table IDs
- Internet Gateway ID

## Cost Considerations

- **NAT Gateways**: $0.045/hour per gateway (~$32/month each)
- **Elastic IPs**: Free when associated with running resources
- **VPC**: No charge for VPC itself
- **Data Transfer**: Charges apply for data transferred through NAT Gateway

To reduce costs in development:
- Set `enable_nat_gateway = false` if outbound internet isn't needed
- Use a single NAT Gateway instead of one per AZ

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Common Issues

### Issue: Resource already exists
**Solution**: Ensure unique names by updating `project_name`, `environment`, or `owner` in `terraform.tfvars`

### Issue: Insufficient permissions
**Solution**: Ensure your AWS user/role has permissions for:
- VPC management
- Subnet creation
- Internet Gateway creation
- NAT Gateway creation
- Route table management

## Security Best Practices

1. Never commit `terraform.tfvars` to version control
2. Use IAM roles instead of access keys when possible
3. Enable VPC Flow Logs for network monitoring
4. Implement least-privilege security groups
5. Use AWS Secrets Manager for sensitive data