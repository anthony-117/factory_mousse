terraform {
  required_version = ">= 1.9"

  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
  }

  # State lives in Oracle Object Storage through its S3-compatible API.
  # bucket, region and endpoints come from -backend-config at init (see docs/runbook.md).
  backend "s3" {
    key                         = "firebase.tfstate"
    use_path_style              = true
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}

provider "google-beta" {
  project               = var.project_id
  billing_project       = var.project_id
  user_project_override = true
}
