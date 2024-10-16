// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

module "resource_names" {
  source  = "terraform.registry.launch.nttdata.com/module_library/resource_name/launch"
  version = "~> 2.0"

  for_each = var.resource_names_map

  logical_product_family  = var.logical_product_family
  logical_product_service = var.logical_product_service
  region                  = var.location
  class_env               = var.class_env
  cloud_resource_type     = each.value.name
  instance_env            = var.instance_env
  maximum_length          = each.value.max_length
}

module "resource_group" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/resource_group/azurerm"
  version = "~> 1.0"

  name     = local.resource_group_name
  location = var.location

  tags = merge(var.tags, { resource_name = module.resource_names["resource_group"].standard })
}

module "monitor_workspace" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/monitor_workspace/azurerm"
  version = "~> 1.0"

  name                = module.resource_names["monitor_workspace"].minimal_random_suffix
  location            = var.location
  resource_group_name = module.resource_group.name

  tags = merge(var.tags, { resource_name = module.resource_names["monitor_workspace"].standard })

  depends_on = [module.resource_group]
}

module "user_assigned_identity" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/user_managed_identity/azurerm"
  version = "~> 1.0"

  resource_group_name         = module.resource_group.name
  location                    = var.location
  user_assigned_identity_name = module.resource_names["user_managed_identity"].minimal_random_suffix

  depends_on = [module.resource_group]
}

module "role_assignment" {
  source  = "terraform.registry.launch.nttdata.com/module_primitive/role_assignment/azurerm"
  version = "~> 1.0"

  principal_id         = module.user_assigned_identity.principal_id
  role_definition_name = "Monitoring Reader"
  scope                = module.monitor_workspace.id

  depends_on = [module.resource_group, module.user_assigned_identity, module.monitor_workspace]
}

module "grafana" {
  source = "../.."

  name                = local.grafana_name
  location            = var.location
  resource_group_name = module.resource_group.name

  api_key_enabled                   = var.api_key_enabled
  deterministic_outbound_ip_enabled = var.deterministic_outbound_ip_enabled
  public_network_access_enabled     = var.public_network_access_enabled
  grafana_major_version             = var.grafana_major_version
  zone_redundancy_enabled           = var.zone_redundancy_enabled
  sku                               = var.sku

  identity_ids = [module.user_assigned_identity.id]

  azure_monitor_workspace_ids = [module.monitor_workspace.id]

  tags = merge(var.tags, { resource_name = module.resource_names["grafana"].standard })

  depends_on = [module.resource_group, module.user_assigned_identity, module.monitor_workspace]
}
