output "server_ip" {
  description = "Set this as the SERVER_IP repository variable."
  value       = oci_core_instance.server.public_ip
}
