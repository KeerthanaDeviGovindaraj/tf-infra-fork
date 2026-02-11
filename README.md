# Terraform Infrastructure as Code

This repository contains Terraform configurations for deploying cloud networking infrastructure on AWS and GCP.

## Repository Structure
```
tf-infra/
├── .github/
│   └── workflows/
│       └── terraform-ci.yml    # GitHub Actions CI/CD workflow
├── aws/                        # AWS infrastructure
│   ├── main.tf                 # VPC, subnets, route tables
│   ├── variables.tf            # Variable declarations
│   ├── outputs.tf              # Output definitions
│   ├── providers.tf            # AWS provider configuration
│   └── terraform.tfvars.example # Example variable values
├── gcp/                        # GCP infrastructure
│   ├── main.tf                 # VPC network, subnets, firewall rules
│   ├── variables.tf            # Variable declarations
│   ├── outputs.tf              # Output definitions
│   ├── providers.tf            # GCP provider configuration
│   └── terraform.tfvars.example # Example variable values
├── .gitignore                  # Git ignore rules
└── README.md                   # This file
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with profiles: `dev` and `demo`
- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) configured with configurations: `dev` and `demo`
- AWS account with appropriate IAM permissions
- GCP project with appropriate service account permissions

## AWS Infrastructure

### Resources Created

- **1 VPC** with DNS support and hostnames enabled
- **3 Public Subnets** across 3 different availability zones
- **3 Private Subnets** across 3 different availability zones
- **1 Internet Gateway** attached to the VPC
- **1 Public Route Table** with route to Internet Gateway
- **1 Private Route Table** for private subnets
- **Route Table Associations** for all subnets

### Usage
```bash
# Navigate to AWS directory
cd aws

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply configuration
terraform apply

# Destroy infrastructure (when needed)
terraform destroy
```

### Configuration

Edit `terraform.tfvars`:
```hcl
aws_profile = "dev"              # or "demo"
vpc_name    = "csye6225-dev-vpc1"
aws_region  = "us-east-1"
```

### Outputs

After applying, Terraform will output:
- VPC ID
- Public and Private Subnet IDs
- Internet Gateway ID
- Route Table IDs
- Availability Zones used

## GCP Infrastructure

### Resources Created

- **1 VPC Network** with custom subnet mode
- **3 Public Subnets** in us-east1 region
- **3 Private Subnets** in us-east1 region
- **1 Internet Route** (0.0.0.0/0 → default internet gateway)
- **Firewall Rules**:
  - Allow SSH (22), HTTP (80), HTTPS (443) from anywhere
  - Deny all other ingress traffic
- **1 Cloud Router** (for future NAT configuration)

### Usage
```bash
# Navigate to GCP directory
cd gcp

# Activate GCP configuration
gcloud config configurations activate dev  # or demo

# Authenticate for Terraform
gcloud auth application-default login

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply configuration
terraform apply

# Destroy infrastructure (when needed)
terraform destroy
```

### Configuration

Edit `terraform.tfvars`:
```hcl
gcp_project_id = "csye6225-dev-487102"
vpc_name       = "csye6225-dev-vpc1"
gcp_region     = "us-east1"
```

### Outputs

After applying, Terraform will output:
- VPC Network ID and Name
- Public and Private Subnet IDs
- Cloud Router ID
- Firewall Rule IDs

## Multiple Deployments

This configuration supports creating multiple VPCs in the same account/project by using unique values for `vpc_name`:
```hcl
# First deployment
vpc_name = "csye6225-dev-vpc1"

# Second deployment
vpc_name = "csye6225-dev-vpc2"
```

All resources will be prefixed with the VPC name to ensure uniqueness.

## CI/CD Pipeline

This repository uses GitHub Actions for continuous integration.

### Workflow Triggers

The CI pipeline runs on:
- Pull requests to `main` branch
- Changes to `aws/`, `gcp/`, or workflow files

### Pipeline Steps

For both AWS and GCP:
1. **Terraform Format Check**: Validates code formatting
2. **Terraform Init**: Initializes providers (without backend)
3. **Terraform Validate**: Validates configuration syntax

### Status Checks

Pull requests must pass all status checks before merging:
- ✅ Terraform AWS - Format and Validate
- ✅ Terraform GCP - Format and Validate

## Branch Protection

The `main` branch is protected with the following rules:
- Pull requests required before merging
- Status checks must pass
- Branches must be up to date
- No bypassing allowed

## Development Workflow

1. **Fork** the repository to your personal namespace
2. **Create a branch** for your changes:
```bash
   git checkout -b feature/my-changes
```
3. **Make changes** to Terraform configurations
4. **Format code**:
```bash
   terraform fmt -recursive
```
5. **Validate locally**:
```bash
   cd aws && terraform validate
   cd ../gcp && terraform validate
```
6. **Commit and push**:
```bash
   git add .
   git commit -m "Description of changes"
   git push origin feature/my-changes
```
7. **Create Pull Request** on GitHub
8. **Wait for CI** checks to pass
9. **Merge** after approval

## Security Considerations

### Sensitive Files

The following files are excluded from version control (`.gitignore`):
- `*.tfvars` - Contains environment-specific values
- `*.tfstate` - Contains infrastructure state (may contain sensitive data)
- `.terraform/` - Provider plugins and modules
- AWS and GCP credentials

### Credentials Management

- **AWS**: Use AWS CLI profiles (`dev`, `demo`) with IAM user access keys
- **GCP**: Use `gcloud auth application-default login` for authentication
- **Never commit** credentials, access keys, or service account keys

### Best Practices

- Always use separate `dev` and `demo` environments
- Review Terraform plans before applying
- Use least privilege IAM policies
- Regularly rotate access keys
- Enable MFA on cloud accounts

## Troubleshooting

### AWS CLI Issues
```bash
# Verify AWS CLI configuration
aws configure list --profile dev
aws sts get-caller-identity --profile dev

# If credentials are invalid, reconfigure
aws configure --profile dev
```

### GCP Authentication Issues
```bash
# Re-authenticate
gcloud auth application-default login --no-launch-browser

# Verify active configuration
gcloud config configurations list
gcloud config list

# Switch configurations
gcloud config configurations activate dev
```

### Terraform Errors
```bash
# Remove local state and re-initialize
rm -rf .terraform .terraform.lock.hcl
terraform init

# Format all files
terraform fmt -recursive

# Validate configuration
terraform validate
```

