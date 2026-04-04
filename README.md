# Terraform Infrastructure as Code - CSYE 6225

This repository contains Terraform configurations for deploying cloud networking infrastructure on AWS and GCP.

## Repository Structure

```
tf-infra/
├── .github/
│   └── workflows/
│       └── terraform-ci.yml        # GitHub Actions CI/CD workflow
├── aws/                            # AWS infrastructure
│   ├── main.tf                     # VPC, subnets, route tables
│   ├── compute-aws.tf              # Launch Template, ASG, ALB
│   ├── rds.tf                      # RDS PostgreSQL instance
│   ├── s3.tf                       # S3 bucket for file storage
│   ├── iam.tf                      # IAM roles and policies
│   ├── route53.tf                  # DNS records
│   ├── ssl.tf                      # ACM certificate and HTTPS listener
│   ├── kms.tf                      # KMS keys for encryption
│   ├── secrets.tf                  # Secrets Manager for DB password
│   ├── lambda.tf                   # Lambda function and SNS trigger
│   ├── variables.tf                # Variable declarations
│   ├── outputs.tf                  # Output definitions
│   ├── providers.tf                # AWS provider configuration
│   ├── user_data.sh                # EC2 userdata script
│   ├── terraform.tfvars.example    # Example variable values (DEV)
│   └── terraform.demo.tfvars.example # Example variable values (DEMO)
├── gcp/                            # GCP infrastructure
│   ├── main.tf
│   ├── compute-gcp.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   └── terraform.tfvars.example
├── .gitignore
└── README.md
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with profiles: `dev` and `demo`
- Google Cloud CLI configured with configurations: `dev` and `demo`
- AWS account with appropriate IAM permissions
- GCP project with appropriate service account permissions

---

## AWS Infrastructure

### Resources Created

- 1 VPC with DNS support and hostnames enabled
- 3 Public Subnets across 3 availability zones
- 3 Private Subnets across 3 availability zones
- 1 Internet Gateway attached to the VPC
- Public and Private Route Tables with associations
- Application Load Balancer (HTTP port 80 + HTTPS port 443)
- Launch Template with latest AMI
- Auto Scaling Group (min 1, max 3, desired 1)
- RDS PostgreSQL instance in private subnets (encrypted with KMS)
- S3 Bucket for file storage (encrypted with KMS)
- IAM Role and policies for EC2 (CloudWatch + S3 + Secrets Manager access)
- Route53 A record (alias) pointing to ALB
- ACM Certificate with DNS validation (DEV) / imported certificate (DEMO)
- KMS Keys for EC2, RDS, S3, and Secrets Manager encryption
- Secrets Manager secret for RDS password (auto-generated)
- Lambda function for email verification (triggered by SNS)
- DynamoDB table for email token tracking
- SNS topic for user registration events

### KMS Encryption Keys

Four separate KMS keys with 90-day automatic rotation:

| Key | Used For |
|-----|----------|
| `ec2-key` | EC2 EBS volume encryption |
| `rds-key` | RDS storage encryption |
| `s3-key` | S3 bucket encryption |
| `secrets-key` | Secrets Manager secret encryption |

### Secrets Manager

The RDS database password is auto-generated and stored in AWS Secrets Manager. EC2 instances retrieve the password at boot time via `user_data.sh` — no passwords are hardcoded anywhere.

```bash
# Password is retrieved at instance launch via:
aws secretsmanager get-secret-value \
  --secret-id csye6225-db-password \
  --region us-east-1
```

### SSL/TLS Configuration

#### DEV Environment
ACM certificate is requested and validated automatically via DNS (Route53):
```hcl
resource "aws_acm_certificate" "dev_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
}
```

#### DEMO Environment
A third-party SSL certificate (Let's Encrypt) is imported into ACM manually, then referenced via `acm_certificate_arn` in `terraform.demo.tfvars`.

**To import a new certificate for DEMO:**
```bash
# Step 1: Obtain certificate via Certbot
sudo certbot certonly --manual --preferred-challenges dns \
  -d demo.keerthana.click

# Step 2: Add the DNS TXT record shown by Certbot to Route53
# (in the demo.keerthana.click hosted zone)

# Step 3: Copy cert files (sudo required)
sudo cp /etc/letsencrypt/live/demo.keerthana.click/cert.pem ~/Desktop/cert.pem
sudo cp /etc/letsencrypt/live/demo.keerthana.click/privkey.pem ~/Desktop/privkey.pem
sudo cp /etc/letsencrypt/live/demo.keerthana.click/fullchain.pem ~/Desktop/fullchain.pem
sudo chmod 644 ~/Desktop/cert.pem ~/Desktop/privkey.pem ~/Desktop/fullchain.pem

# Step 4: Import into ACM
aws acm import-certificate \
  --certificate fileb://~/Desktop/cert.pem \
  --private-key fileb://~/Desktop/privkey.pem \
  --certificate-chain fileb://~/Desktop/fullchain.pem \
  --region us-east-1 \
  --profile demo

# Step 5: Clean up local cert files
rm ~/Desktop/cert.pem ~/Desktop/privkey.pem ~/Desktop/fullchain.pem

# Step 6: Update terraform.demo.tfvars with the returned CertificateArn
```

> The certificate expires on **2026-07-03** and must be renewed before then.

### IAM Roles & Policies

The IAM role grants the EC2 instance:
- **CloudWatchAgentServerPolicy** — publish logs and metrics
- **S3 Policy** — scoped access to the app S3 bucket
- **Secrets Manager Policy** — read-only access to the DB password secret
- **KMS Policy** — decrypt access for EC2/S3/RDS/Secrets keys

### DNS

| Zone | Account | Zone ID |
|------|---------|---------|
| `keerthana.click` | Root | (root account) |
| `dev.keerthana.click` | DEV | `Z06555121LSBIWVMZVAH` |
| `demo.keerthana.click` | DEMO | `Z04656191C89OSEWJWNC8` |

The application is accessible at:
- DEV: `https://dev.keerthana.click`
- DEMO: `https://demo.keerthana.click`

### Auto Scaling Group

The ASG is configured with:
- Minimum: 1 instance
- Maximum: 3 instances
- Desired: 1 instance
- Health check type: ELB
- Instance refresh triggered automatically on new AMI via CI/CD

---

## Usage

### DEV Environment

```bash
cd aws

cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
terraform destroy
```

### DEMO Environment

```bash
cd aws

cp terraform.demo.tfvars.example terraform.demo.tfvars
# Edit terraform.demo.tfvars with your values

terraform init
terraform plan -var-file=terraform.demo.tfvars
terraform apply -var-file=terraform.demo.tfvars
terraform destroy -var-file=terraform.demo.tfvars
```

### Configuration Variables

| Variable | DEV | DEMO |
|----------|-----|------|
| `aws_profile` | `dev` | `demo` |
| `domain_name` | `dev.keerthana.click` | `demo.keerthana.click` |
| `route53_zone_id` | `Z06555121LSBIWVMZVAH` | `Z04656191C89OSEWJWNC8` |
| `acm_certificate_arn` | `""` (ACM manages) | `arn:aws:acm:...` |
| `ses_from_email` | `no-reply@dev.keerthana.click` | `no-reply@demo.keerthana.click` |

---

## CI/CD Pipeline

### Terraform Validate Workflow

Triggers on pull requests to `main`. Steps:
1. Terraform Format Check
2. Terraform Init
3. Terraform Validate (AWS + GCP)

### Status Checks

- Terraform AWS - Format and Validate
- Terraform GCP - Format and Validate

---

## Security Considerations

- `terraform.tfvars` and `terraform.demo.tfvars` are excluded from version control
- No credentials, passwords, or access keys committed to the repository
- RDS password is auto-generated and stored in Secrets Manager — never hardcoded
- All data at rest encrypted with dedicated KMS keys (90-day rotation)
- RDS deployed in private subnets (not publicly accessible)
- EC2 instances not directly accessible — traffic flows through ALB only
- IAM roles use least privilege policies
- HTTPS enforced via ALB listener on port 443

---

## Troubleshooting

```bash
# Check AWS profile
aws sts get-caller-identity --profile dev
aws sts get-caller-identity --profile demo

# Reset Terraform state
rm -rf .terraform .terraform.lock.hcl
terraform init

# Format and validate
terraform fmt -recursive
terraform validate
```
