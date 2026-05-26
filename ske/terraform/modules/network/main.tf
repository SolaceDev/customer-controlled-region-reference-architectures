locals {
  project_labels = merge({
    "networkArea" = stackit_network_area_region.cluster_network_region.network_area_id,
    },
    var.create_routing_table ? {
      "preview/routingTables" = "true"
    } : {}
  )
}

resource "stackit_network_area" "this" {
  organization_id = var.organization_id
  name            = "${var.name}-sna"
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
  routing_table_id = try(stackit_routing_table.this.routing_table_id, null)
}

resource "stackit_resourcemanager_project" "cluster_project" {
  parent_container_id = var.organization_id
  name                = var.name
  owner_email         = var.email
  labels              = local.project_labels
}

resource "stackit_routing_table" "this" {
  count           = var.create_routing_table ? 1 : 0
  name            = "${var.name}-rt"
  organization_id = var.organization_id
  network_area_id = stackit_network_area.this.network_area_id
}

check "static_routes_deprecation" {
  assert {
    condition     = var.create_routing_table
    error_message = "The static routes API is being deprecated. Set create_routing_table to true to use the routing tables API instead."
  }
}
