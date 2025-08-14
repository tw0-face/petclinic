provider "google" {
  project = local.project_id
  region  = local.region
}

terraform {

  backend "gcs" {
    bucket = "tf-state-petclinic-mostafa"
    prefix = "terraform/state"
  }

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.43.0"
    }
  }
}