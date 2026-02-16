
data "google_compute_image" "webapp" {
  family  = "webapp"
  project = var.gcp_project_id
}


data "google_compute_default_service_account" "default" {
}


resource "google_compute_firewall" "webapp" {
  name    = "${var.vpc_name}-webapp-firewall"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", var.application_port]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webapp"]

  description = "Allow SSH, HTTP, HTTPS, and application traffic to webapp instances"
}

resource "google_compute_instance" "webapp" {
  name         = "${var.vpc_name}-webapp-instance"
  machine_type = var.gcp_machine_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.webapp.self_link
      size  = 25
      type  = "pd-balanced"
    }
    auto_delete = true
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.public[0].name

    access_config {
    }
  }

  tags = ["webapp"]

  deletion_protection = false

  metadata = {
  }

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_compute_subnetwork.public,
    google_compute_firewall.webapp
  ]
}