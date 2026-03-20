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
│   ├── compute-aws.tf              # EC2 instance configuration
│   ├── rds.tf                      # RDS PostgreSQL instance
│   ├── s3.tf                       # S3 bucket for syllabus files
│   ├── iam.tf                      # IAM roles and policies
│   ├── route53.tf                  # DNS records
│   ├── variables.tf                # Variable declarations
│   ├── outputs.tf                  # Output definitions
│   ├── providers.tf                # AWS provider configuration
│   ├── user_data.sh                # EC2 userdata script
│   └── terraform.tfvars.example   # Example variable values
├── gcp/                            # GCP infrastructure
│   ├── main.tf                     # VPC network, subnets, firewall rules
│   ├── compute-gcp.tf              # GCP compute instance
│   ├── variables.tf                # Variable declarations
│   ├── outputs.tf                  # Output definitions
│   ├── providers.tf                # GCP provider configuration
│   └── terraform.tfvars.example   # Example variable values
├── .gitignore                      # Git ignore rules
└── README.md                       # This file
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
- 1 Public Route Table with route to Internet Gateway
- 1 Private Route Table for private subnets
- Route Table Associations for all subnets
- EC2 Instance running the web application AMI
- RDS PostgreSQL instance in private subnets
- S3 Bucket for syllabus file storage
- IAM Role and policies for EC2 (CloudWatch + S3 access)
- Route53 A record pointing to EC2 instance

### IAM Roles & Policies

The IAM role created by Terraform grants the EC2 instance:
- **CloudWatchAgentServerPolicy** — allows the CloudWatch agent to publish logs and metrics
- **S3 Policy** — scoped access to the syllabus S3 bucket (PutObject, GetObject, DeleteObject, ListBucket)

> No AWS credentials are hardcoded in the AMI or EC2 instance. The IAM role is attached via instance profile.

### CloudWatch Agent

The EC2 userdata script (`user_data.sh`) configures and starts the CloudWatch agent on every instance launch:

```bash
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json \
  -s

systemctl enable amazon-cloudwatch-agent
systemctl restart amazon-cloudwatch-agent
```

### DNS

Route53 is managed by Terraform:
- A record for `dev.keerthana.click` → EC2 public IP
- A record for `demo.keerthana.click` → EC2 public IP

### Usage

```bash
cd aws

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# Initialize
terraform init

# Preview
terraform plan -var='db_password=YourPassword'

# Apply
terraform apply -var='db_password=YourPassword'

# Destroy
terraform destroy -var='db_password=YourPassword'
```

### Configuration

Edit `terraform.tfvars`:

```hcl
aws_region           = "us-east-1"
aws_profile          = "dev"
vpc_name             = "csye6225-vpc"
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
application_port     = 8080
aws_instance_type    = "t2.micro"
domain_name          = "dev.keerthana.click"
```

### Outputs

After applying, Terraform outputs:
- VPC ID
- Public and Private Subnet IDs
- Internet Gateway ID
- Route Table IDs
- EC2 public IP and app URL
- RDS endpoint
- S3 bucket name

---

## GCP Infrastructure

### Resources Created

- 1 VPC Network with custom subnet mode
- 3 Public Subnets in `us-east1` region
- 3 Private Subnets in `us-east1` region
- 1 Internet Route (0.0.0.0/0 → default internet gateway)
- Firewall Rules: Allow SSH (22), HTTP (80), HTTPS (443), app port (8080)
- GCP Compute Instance running the web application image
- 1 Cloud Router

### Usage

```bash
cd gcp

gcloud config configurations activate dev
gcloud auth application-default login

cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

terraform init
terraform plan
terraform apply
terraform destroy
```

### Configuration

Edit `terraform.tfvars`:

```hcl
gcp_project_id = "csye6225-dev-487102"
vpc_name       = "csye6225-dev-vpc1"
gcp_region     = "us-east1"
```

---

## CI/CD Pipeline

This repository uses GitHub Actions for continuous integration.

### Workflow Triggers

- Pull requests to `main` branch
- Changes to `aws/`, `gcp/`, or workflow files

### Pipeline Steps

- Terraform Format Check
- Terraform Init
- Terraform Validate

### Status Checks

Pull requests must pass all status checks before merging:
- ✅ Terraform AWS - Format and Validate
- ✅ Terraform GCP - Format and Validate

---

## DNS Setup

### Zone Delegation

| Zone | Account | Type |
|------|---------|------|
| `keerthana.click` | Root | Public Hosted Zone |
| `dev.keerthana.click` | Dev | Public Hosted Zone |
| `demo.keerthana.click` | Demo | Public Hosted Zone |

NS records for `dev` and `demo` subdomains are configured in the root account for zone delegation.

The application is accessible at:
- Dev: `http://dev.keerthana.click:8080`
- Demo: `http://demo.keerthana.click:8080`

---

## Development Workflow

1. Fork the repository
2. Create a feature branch:
   ```bash
   git checkout -b feature/my-changes
   ```
3. Make changes
4. Format and validate:
   ```bash
   terraform fmt -recursive
   cd aws && terraform validate
   cd ../gcp && terraform validate
   ```
5. Commit and push
6. Create Pull Request
7. Wait for CI checks to pass
8. Merge after approval

---

## Security Considerations

- `terraform.tfvars` is excluded from version control
- No credentials or access keys committed to the repository
- IAM roles use least privilege policies
- RDS is deployed in private subnets (not publicly accessible)
- S3 bucket access is scoped to the specific bucket only
- CloudWatch agent uses IAM role — no hardcoded AWS credentials

---

## Troubleshooting

### AWS CLI Issues

```bash
aws configure list --profile dev
aws sts get-caller-identity --profile dev
aws configure --profile dev
```

### GCP Authentication Issues

```bash
gcloud auth application-default login --no-launch-browser
gcloud config configurations list
gcloud config configurations activate dev
```

### Terraform Errors

```bash
rm -rf .terraform .terraform.lock.hcl
terraform init
terraform fmt -recursive
terraform validate
```