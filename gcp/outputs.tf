output "network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.main.id
}

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.main.name
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = google_compute_subnetwork.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = google_compute_subnetwork.private[*].id
}

output "router_id" {
  description = "ID of the Cloud Router"
  value       = google_compute_router.main.id
}

output "firewall_rule_ids" {
  description = "IDs of firewall rules"
  value = {
    allow_public = google_compute_firewall.allow_public.id
    deny_all     = google_compute_firewall.deny_all.id
  }
}

# GCP Instance Outputs
output "gcp_instance_name" {
  description = "Name of the GCP instance"
  value       = google_compute_instance.webapp.name
}

output "gcp_instance_external_ip" {
  description = "External IP of the GCP instance"
  value       = google_compute_instance.webapp.network_interface[0].access_config[0].nat_ip
}

output "gcp_instance_internal_ip" {
  description = "Internal IP of the GCP instance"
  value       = google_compute_instance.webapp.network_interface[0].network_ip
}

output "gcp_image_name" {
  description = "Image name used"
  value       = data.google_compute_image.webapp.name
}

output "gcp_application_url" {
  description = "Application URL"
  value       = "http://${google_compute_instance.webapp.network_interface[0].access_config[0].nat_ip}:${var.application_port}"
}

output "gcp_metadata_endpoint" {
  description = "Metadata endpoint URL"
  value       = "http://${google_compute_instance.webapp.network_interface[0].access_config[0].nat_ip}:${var.application_port}/v1/metadata"
}