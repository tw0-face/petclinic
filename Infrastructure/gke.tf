resource "google_container_cluster" "management-gke" {
  name                     = "management-cluster"
  location                 = "us-central1-a"
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = google_compute_network.vpc.self_link
  subnetwork               = google_compute_subnetwork.private-management.self_link
  networking_mode          = "VPC_NATIVE"

  deletion_protection = false


  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${local.project_id}.svc.id.goog"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "k8s-pods-management"
    services_secondary_range_name = "k8s-services-management"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    # When creating a private cluster, the 'master_ipv4_cidr_block' has to be defined and the size must be /28
    master_ipv4_cidr_block  = "192.168.0.0/28"
  }

  # With a private cluster, it is highly recommended to restrict access to the cluster master
  # However, for testing purposes we will allow all inbound traffic.
  master_authorized_networks_config {
      cidr_blocks {
          cidr_block   = "0.0.0.0/0"
          display_name = "all-for-testing-management"
        } 
    }

}

resource "google_container_cluster" "prod-gke" {
  name                     = "prod-cluster"
  location                 = "us-central1-a"
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = google_compute_network.vpc.self_link
  subnetwork               = google_compute_subnetwork.private-prod.self_link
  networking_mode          = "VPC_NATIVE"

  deletion_protection = false


  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  release_channel {
    channel = "REGULAR"
  }


  ip_allocation_policy {
    cluster_secondary_range_name  = "k8s-pods-prod"
    services_secondary_range_name = "k8s-services-prod"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    # When creating a private cluster, the 'master_ipv4_cidr_block' has to be defined and the size must be /28
    master_ipv4_cidr_block  = "192.168.1.0/28"
  }

  # With a private cluster, it is highly recommended to restrict access to the cluster master
  # However, for testing purposes we will allow all inbound traffic.
  master_authorized_networks_config {
      cidr_blocks {
          cidr_block   = "0.0.0.0/0"
          display_name = "all-for-testing-prod"
        } 
    }

}


resource "google_service_account" "petclinic" {
  account_id = "petclinic-sa"
}

resource "google_project_iam_member" "gke_artifact_registry" {
  project = local.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.petclinic.email}"
}

resource "google_container_node_pool" "management-vms" {
  name    = "management-nodepool"
  cluster = google_container_cluster.gke.id
  location = "us-central1-a"
  node_count = 2

  autoscaling {
    total_min_node_count = 2
    total_max_node_count = 4
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = false
    machine_type = "e2-standard-4" # 4vCPUs, 16RAM

    labels = {
      role = "management"
    }


    service_account = google_service_account.petclinic.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}


resource "google_container_node_pool" "prod-vms" {
  name    = "prod-nodepool"
  cluster = google_container_cluster.gke.id
  location = "us-central1-a"
  node_count = 1

  autoscaling {
    total_min_node_count = 2
    total_max_node_count = 4
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = true
    machine_type = "e2-standard-2" # 2vCPUs, 4RAM

    labels = {
      role = "petclinic-prod"
    }


    service_account = google_service_account.petclinic.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

