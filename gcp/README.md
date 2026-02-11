# GCP Infrastructure

This directory contains Terraform configurations for GCP networking infrastructure.

## Architecture

The infrastructure creates:

- **VPC Network**: Custom VPC with regional routing
- **Subnets**: Custom IP ranges with Private Google Access
- **Cloud Router**: Enables Cloud NAT functionality
- **Cloud NAT**: Provides outbound internet access for private instances
- **Firewall Rules**: Network security policies
- **Internal Communication**: Allow traffic between subnets

## Prerequisites

1. GCP CLI (gcloud) installed
2. GCP project with billing enabled
3. Terraform >= 1.0
4. Service account with appropriate permissions

## Setup

### 1. Configure GCP Authentication

```bash
gcloud auth application-default login
```

Or use a service account:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

### 2. Create GCP Project (if needed)

```bash
gcloud projects create your-project-id
gcloud config set project your-project-id
```

### 3. Enable Required APIs

```bash
gcloud services enable compute.googleapis.com
gcloud services enable servicenetworking.googleapis.com
```

### 4. Create terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
gcp_project_id = "your-gcp-project-id"
gcp_region     = "us-central1"
project_name   = "myproject"
environment    = "dev"
owner          = "yourname"
```

### 5. Initialize Terraform

```bash
terraform init
```

### 6. Review the Plan

```bash
terraform plan
```

### 7. Apply Configuration

```bash
terraform apply
```

## Resource Naming Convention

All resources follow the pattern: `{project_name}-{environment}-{owner}-{resource_type}`

Example: `myproject-dev-john-vpc`

## Outputs

After applying, Terraform will output:

- VPC network ID and name
- Subnet IDs and CIDR ranges
- Cloud Router ID
- Cloud NAT ID
- Firewall rule IDs

## Firewall Rules

The configuration includes:

1. **SSH Access**: Port 22 from anywhere (customizable)
2. **HTTP/HTTPS Access**: Ports 80 and 443 (optional)
3. **Internal Communication**: All traffic between subnets

Customize firewall rules in `terraform.tfvars`:

```hcl
firewall_rules = [
  {
    name          = "allow-ssh"
    direction     = "INGRESS"
    priority      = 1000
    source_ranges = ["YOUR_IP/32"]  # Restrict to your IP
    allow = [
      {
        protocol = "tcp"
        ports    = ["22"]
      }
    ]
  }
]
```

## Cost Considerations

- **VPC Network**: No charge
- **Subnets**: No charge
- **Cloud NAT**: $0.045/hour + data processing charges
- **Cloud Router**: No charge
- **Egress Traffic**: Varies by destination

To reduce costs in development:
- Set `enable_cloud_nat = false` if outbound internet isn't needed
- Delete unused resources promptly

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Common Issues

### Issue: API not enabled
**Solution**: 
```bash
gcloud services enable compute.googleapis.com
```

### Issue: Insufficient permissions
**Solution**: Ensure your service account has these roles:
- `roles/compute.networkAdmin`
- `roles/compute.securityAdmin`

### Issue: Project ID not found
**Solution**: Verify project ID with:
```bash
gcloud projects list
```

## Security Best Practices

1. Never commit `terraform.tfvars` or service account keys to version control
2. Use VPC Service Controls for additional security
3. Restrict firewall rules to specific IP ranges
4. Enable VPC Flow Logs for network monitoring
5. Use Google Secret Manager for sensitive data
6. Enable Private Google Access for private subnets

## Advanced Configuration

### Multiple Regions

To deploy across multiple regions, add more subnet configurations:

```hcl
subnet_configs = [
  {
    name          = "subnet-us-central1"
    ip_cidr_range = "10.0.1.0/24"
    region        = "us-central1"
  },
  {
    name          = "subnet-us-east1"
    ip_cidr_range = "10.1.1.0/24"
    region        = "us-east1"
  }
]
```

### Custom DNS

Add to subnets if needed:

```hcl
resource "google_dns_managed_zone" "private_zone" {
  name        = "${var.project_name}-private-zone"
  dns_name    = "internal.example.com."
  description = "Private DNS zone"
  visibility  = "private"
  
  private_visibility_config {
    networks {
      network_url = google_compute_network.main.id
    }
  }
}
```