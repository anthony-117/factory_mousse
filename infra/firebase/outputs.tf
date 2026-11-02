output "site_url" {
  description = "The web app's address. Add it to CORS_ALLOWED_ORIGINS in the BACKEND_ENV secret."
  value       = google_firebase_hosting_site.main.default_url
}
