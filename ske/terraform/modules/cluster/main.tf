data "stackit_ske_kubernetes_versions" "supported" {
  version_state = "SUPPORTED"
}

locals {
  # Filter available versions to those matching the requested major.minor prefix,
  # then pick the newest patch release (first match, API returns descending order).
  matching_versions = [
    for v in data.stackit_ske_kubernetes_versions.supported.kubernetes_versions : v.version
    if startswith(v.version, "${var.kubernetes_version}.")
  ]
  resolved_kubernetes_version = local.matching_versions[0]

  acl_extension = length(var.kubernetes_api_authorized_networks) > 0 ? {
    enabled       = true
    allowed_cidrs = var.kubernetes_api_authorized_networks
  } : null

  dns_extension = var.dns_enabled ? {
    enabled = true
    zones   = var.dns_zones
  } : null

  observability_extension = var.observability_enabled ? {
    enabled     = true
    instance_id = var.observability_instance_id
  } : null

  cluster_extensions = merge(
    local.acl_extension == null ? {} : { acl = local.acl_extension },
    local.dns_extension == null ? {} : { dns = local.dns_extension },
    local.observability_extension == null ? {} : { observability = local.observability_extension },
  )
}

resource "stackit_ske_cluster" "this" {
  name                   = var.cluster_name
  project_id             = var.project_id
  kubernetes_version_min = local.resolved_kubernetes_version

  maintenance = {
    enable_kubernetes_version_updates    = false
    enable_machine_image_version_updates = false
    start                                = "02:00:00Z"
    end                                  = "04:00:00Z"
  }

  node_pools = var.node_pools

  network = {
    control_plane = {
      access_scope = var.kubernetes_api_public_access ? "PUBLIC" : "SNA"
    }
    id = var.network_id
  }

  extensions = length(local.cluster_extensions) > 0 ? local.cluster_extensions : null
}
