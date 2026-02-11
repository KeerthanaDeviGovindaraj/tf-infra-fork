resource "google_compute_network" "main" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  project                 = var.gcp_project_id
}

resource "google_compute_subnetwork" "public" {
  count         = 3
  name          = "${var.vpc_name}-public-subnet-${count.index + 1}"
  ip_cidr_range = var.public_subnet_cidrs[count.index]
  region        = var.gcp_region
  network       = google_compute_network.main.id
  project       = var.gcp_project_id

  private_ip_google_access = false
}

resource "google_compute_subnetwork" "private" {
  count         = 3
  name          = "${var.vpc_name}-private-subnet-${count.index + 1}"
  ip_cidr_range = var.private_subnet_cidrs[count.index]
  region        = var.gcp_region
  network       = google_compute_network.main.id
  project       = var.gcp_project_id

  private_ip_google_access = true
}

resource "google_compute_route" "internet" {
  name             = "${var.vpc_name}-internet-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.main.id
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  project          = var.gcp_project_id
}

resource "google_compute_firewall" "allow_public" {
  name    = "${var.vpc_name}-allow-public"
  network = google_compute_network.main.id
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["public"]
  priority      = 1000
}

resource "google_compute_firewall" "deny_all" {
  name    = "${var.vpc_name}-deny-all"
  network = google_compute_network.main.id
  project = var.gcp_project_id

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  priority      = 65534
}

resource "google_compute_router" "main" {
  name    = "${var.vpc_name}-router"
  region  = var.gcp_region
  network = google_compute_network.main.id
  project = var.gcp_project_id
}