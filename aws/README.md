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
## SSL Certificate Import (DEMO Environment)

The DEMO environment uses a Let's Encrypt SSL certificate imported into AWS Certificate Manager.

### Steps to import certificate for DEMO:

```bash
# Step 1: Obtain certificate via Certbot
sudo certbot certonly --manual --preferred-challenges dns \
  -d demo.keerthana.click

# Step 2: Copy cert files
sudo cp /etc/letsencrypt/live/demo.keerthana.click/cert.pem ~/Desktop/cert.pem
sudo cp /etc/letsencrypt/live/demo.keerthana.click/privkey.pem ~/Desktop/privkey.pem
sudo cp /etc/letsencrypt/live/demo.keerthana.click/fullchain.pem ~/Desktop/fullchain.pem
sudo chmod 644 ~/Desktop/cert.pem ~/Desktop/privkey.pem ~/Desktop/fullchain.pem

# Step 3: Import into ACM
aws acm import-certificate \
  --certificate fileb://~/Desktop/cert.pem \
  --private-key fileb://~/Desktop/privkey.pem \
  --certificate-chain fileb://~/Desktop/fullchain.pem \
  --region us-east-1 \
  --profile demo

# Step 4: Clean up
rm ~/Desktop/cert.pem ~/Desktop/privkey.pem ~/Desktop/fullchain.pem

# Step 5: Update terraform.tfvars with the returned CertificateArn
# acm_certificate_arn = "arn:aws:acm:us-east-1:156667831591:certificate/..."
```
