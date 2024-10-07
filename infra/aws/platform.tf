
// variables calculated before ami data is retrieved
locals {
  // find the unique platforms actually used in the node_group_definitions, so that we can combine platform definiton and ami data together
  // - this is unique to avoid repeated ami pulls for the same definition
  // - only node-group platforms are pulled to avoid pulling images data sources that are not used anywhere
  unique_used_platforms = distinct([for ngd in var.nodegroups : ngd.platform])
  platforms_with_ami = { for k, p in local.unique_used_platforms : p => module.platform[k].platform }
}

module "platform" {
  count  = length(local.unique_used_platforms)
  source  = "terraform-mirantis-modules/provision-aws/mirantis//modules/platform"
  version = "0.1.2"

  platform_key     = local.unique_used_platforms[count.index]
  windows_password = var.windows_password
}

// variables calculated after ami data is pulled
