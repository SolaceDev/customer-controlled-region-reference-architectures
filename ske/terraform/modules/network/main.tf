resource "stackit_network_area" "this" {
  organization_id = var.organization_id
  name            = "${var.name}-sna"
  labels          = var.common_labels

  # The project-scoped network references this network area. On destroy,
  # Terraform must delete the network area (and its region binding) before
  # the project. Without this dependency Terraform may destroy the project
  # first, causing the network area region deletion to fail with
  # "has still active projects".
  depends_on = [stackit_network.this]
}

resource "stackit_network_area_region" "this" {
  region          = var.region
  organization_id = var.organization_id
  network_area_id = stackit_network_area.this.network_area_id
  ipv4 = {
    transfer_network = var.transfer_network_cidr
    network_ranges   = concat([{ prefix = var.cluster_cidr }], [for range in var.additional_sna_ranges : { prefix = range }])
  }
}

resource "stackit_network" "this" {
  name             = "${var.name}-network"
  ipv4_prefix      = var.cluster_cidr
  project_id       = var.project_id
  ipv4_nameservers = var.network_dns_servers
  labels           = var.common_labels
}
