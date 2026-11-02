# The project and its site already exist, so OpenTofu adopts them instead of creating new ones.
# Firestore, Auth and storage are not here yet: they depend on the database decision and on the Blaze plan.
import {
  provider = google-beta
  to       = google_firebase_project.main
  id       = "projects/${var.project_id}"
}

import {
  provider = google-beta
  to       = google_firebase_hosting_site.main
  id       = "projects/${var.project_id}/sites/${var.project_id}"
}

resource "google_project_service" "apis" {
  provider = google-beta
  for_each = toset(["firebase.googleapis.com", "firebasehosting.googleapis.com", "serviceusage.googleapis.com"])

  service            = each.value
  disable_on_destroy = false
}

resource "google_firebase_project" "main" {
  provider = google-beta

  depends_on = [google_project_service.apis]

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_firebase_hosting_site" "main" {
  provider = google-beta
  site_id  = var.project_id

  depends_on = [google_firebase_project.main]

  lifecycle {
    prevent_destroy = true
  }
}
