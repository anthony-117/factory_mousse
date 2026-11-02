locals {
  name       = "travelgenie"
  anywhere   = "0.0.0.0/0"
  tcp        = "6"
  open_ports = [80, 443]
}

data "oci_identity_availability_domains" "all" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "ubuntu" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_vcn" "main" {
  compartment_id = var.tenancy_ocid
  display_name   = local.name
  cidr_blocks    = ["10.0.0.0/16"]
  dns_label      = local.name
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = local.name
}

resource "oci_core_route_table" "main" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = local.name

  route_rules {
    destination       = local.anywhere
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

resource "oci_core_security_list" "main" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = local.name

  egress_security_rules {
    destination = local.anywhere
    protocol    = "all"
  }

  ingress_security_rules {
    source   = var.ssh_allowed_cidr
    protocol = local.tcp

    tcp_options {
      min = 22
      max = 22
    }
  }

  dynamic "ingress_security_rules" {
    for_each = local.open_ports

    content {
      source   = local.anywhere
      protocol = local.tcp

      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }
}

resource "oci_core_subnet" "main" {
  compartment_id    = var.tenancy_ocid
  vcn_id            = oci_core_vcn.main.id
  display_name      = local.name
  cidr_block        = "10.0.1.0/24"
  dns_label         = "main"
  route_table_id    = oci_core_route_table.main.id
  security_list_ids = [oci_core_security_list.main.id]
}

# The whole Always Free ARM allowance: 2 OCPUs and 12 GB.
resource "oci_core_instance" "server" {
  compartment_id      = var.tenancy_ocid
  availability_domain = data.oci_identity_availability_domains.all.availability_domains[var.availability_domain_index].name
  display_name        = local.name
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.main.id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(file("${path.module}/cloud-init.yaml"))
  }

  lifecycle {
    # Recreating the server can fail for lack of free capacity, so OpenTofu must never replace it by accident.
    prevent_destroy = true
    # A newer Ubuntu image or changed first-boot script must not replace a running server.
    ignore_changes = [source_details, metadata]
  }
}
