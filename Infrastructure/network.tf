resource "google_compute_network" "vpc" {
  name                            = "main"
  routing_mode                    = "REGIONAL"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true

  depends_on = [google_project_service.apis]
}

resource "google_compute_route" "default_route" {
  name             = "default-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc.name
  next_hop_gateway = "default-internet-gateway"
}

resource "google_compute_subnetwork" "public" {
  name                     = "public"
  ip_cidr_range            = "10.0.0.0/19" #8,192 ips
  region                   = local.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
  stack_type               = "IPV4_ONLY"
}

resource "google_compute_subnetwork" "private-management" {
  name                     = "private-management"
  ip_cidr_range            = "10.0.32.0/19"
  region                   = local.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
  stack_type               = "IPV4_ONLY"

# https://cloud.google.com/blog/products/containers-kubernetes/best-practices-for-kubernetes-pod-ip-allocation-in-gke
  secondary_ip_range {
    range_name    = "k8s-pods-management"
    ip_cidr_range = "100.64.0.0/10"
  }
  secondary_ip_range {
    range_name    = "k8s-services-management"
    ip_cidr_range = "100.128.128.0/21"
  }
}

resource "google_compute_subnetwork" "private-prod" {
  name                     = "private-prod"
  ip_cidr_range            = "10.0.64.0/19"
  region                   = local.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
  stack_type               = "IPV4_ONLY"
# https://www.microfocus.com/documentation/arcsight/arcsight-platform-22.1/arcsight-admin-guide-22.1/Content/deployment_plan/Kub_subnets_about.htm?TocPath=Planning%20to%20Install%20and%20Deploy%7C_____7#:~:text=In%20order%20to%20do%20so,0.0%2F16).
  secondary_ip_range {
    range_name    = "k8s-pods-prod"
    ip_cidr_range = "172.16.0.0/16"
  }

  secondary_ip_range {
    range_name    = "k8s-services-prod"
    ip_cidr_range = "172.17.17.0/24"
  }
}

# static ip for nat
resource "google_compute_address" "nat" {
  name         = "nat"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"

  depends_on = [google_project_service.apis]
}

resource "google_compute_router" "router" {
  name    = "router"
  region  = local.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name   = "nat"
  region = local.region
  router = google_compute_router.router.name

  nat_ip_allocate_option             = "MANUAL_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ips                            = [google_compute_address.nat.self_link]

  subnetwork {
    name                    = google_compute_subnetwork.private-management.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name                    = google_compute_subnetwork.private-prod.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}
