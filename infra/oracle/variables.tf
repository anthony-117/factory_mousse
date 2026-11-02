variable "tenancy_ocid" {
  description = "Oracle tenancy OCID. Always Free resources are created in the tenancy's root compartment."
  type        = string
}

variable "user_ocid" {
  description = "OCID of the Oracle user OpenTofu acts as."
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of that user's API key."
  type        = string
}

variable "private_key_path" {
  description = "Path to that user's API private key."
  type        = string
}

variable "region" {
  description = "The tenancy's home region. Always Free compute only exists there."
  type        = string
}

variable "ssh_public_key" {
  description = "Public key allowed to log in to the server as the ubuntu user."
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "Who can reach SSH. Open by default because GitHub's runners have no fixed address; logging in still needs the key."
  type        = string
  default     = "0.0.0.0/0"
}

variable "availability_domain_index" {
  description = "Which availability domain to use. Change it if creating the server fails with 'out of host capacity'."
  type        = number
  default     = 0
}
