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