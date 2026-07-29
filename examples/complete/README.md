# complete

This example deploys a fully working Azure-managed Grafana instance and its supporting infrastructure (resource group, Azure Monitor workspace, user-assigned managed identity, role assignment) so the primitive can be validated end-to-end.

## Usage

```hcl
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
  instance_resource       = var.instance_resource
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

  identity_ids = var.identity_ids != null ? var.identity_ids : [module.user_assigned_identity.id]

  azure_monitor_workspace_ids = var.azure_monitor_workspace_ids != null ? var.azure_monitor_workspace_ids : toset([module.monitor_workspace.id])

  tags = merge(var.tags, { resource_name = module.resource_names["grafana"].standard })

  depends_on = [module.resource_group, module.user_assigned_identity, module.monitor_workspace]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0, < 2.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_grafana"></a> [grafana](#module\_grafana) | ../.. | n/a |
| <a name="module_monitor_workspace"></a> [monitor\_workspace](#module\_monitor\_workspace) | terraform.registry.launch.nttdata.com/module_primitive/monitor_workspace/azurerm | ~> 1.0 |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | terraform.registry.launch.nttdata.com/module_primitive/resource_group/azurerm | ~> 1.0 |
| <a name="module_resource_names"></a> [resource\_names](#module\_resource\_names) | terraform.registry.launch.nttdata.com/module_library/resource_name/launch | ~> 2.0 |
| <a name="module_role_assignment"></a> [role\_assignment](#module\_role\_assignment) | terraform.registry.launch.nttdata.com/module_primitive/role_assignment/azurerm | ~> 1.3 |
| <a name="module_user_assigned_identity"></a> [user\_assigned\_identity](#module\_user\_assigned\_identity) | terraform.registry.launch.nttdata.com/module_primitive/user_managed_identity/azurerm | ~> 1.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_key_enabled"></a> [api\_key\_enabled](#input\_api\_key\_enabled) | Whether to enable API keys for the managed grafana instance. Defaults to false | `bool` | `false` | no |
| <a name="input_azure_monitor_workspace_ids"></a> [azure\_monitor\_workspace\_ids](#input\_azure\_monitor\_workspace\_ids) | Optional set of Azure Monitor workspace resource IDs to integrate with the Grafana instance.<br/>    If null, the example provisions an Azure Monitor workspace internally and uses it. | `set(string)` | `null` | no |
| <a name="input_class_env"></a> [class\_env](#input\_class\_env) | (Required) Environment where resource is going to be deployed. For example. dev, qa, uat | `string` | `"dev"` | no |
| <a name="input_deterministic_outbound_ip_enabled"></a> [deterministic\_outbound\_ip\_enabled](#input\_deterministic\_outbound\_ip\_enabled) | Whether to enable deterministic outbound IP for the managed grafana instance. Defaults to false | `bool` | `false` | no |
| <a name="input_grafana_major_version"></a> [grafana\_major\_version](#input\_grafana\_major\_version) | Major version of Grafana to deploy | `string` | `"12"` | no |
| <a name="input_identity_ids"></a> [identity\_ids](#input\_identity\_ids) | Optional list of user-assigned managed identity resource IDs to assign to the Grafana instance.<br/>    If null, the example provisions a user-assigned identity internally and uses it. | `list(string)` | `null` | no |
| <a name="input_instance_env"></a> [instance\_env](#input\_instance\_env) | Number that represents the instance of the environment. | `number` | `0` | no |
| <a name="input_instance_resource"></a> [instance\_resource](#input\_instance\_resource) | Number that represents the instance of the resource. | `number` | `0` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where the resources will be created (e.g. eastus, westus2). | `string` | `"eastus"` | no |
| <a name="input_logical_product_family"></a> [logical\_product\_family](#input\_logical\_product\_family) | (Required) Name of the product family for which the resource is created.<br/>    Example: org\_name, department\_name. | `string` | `"launch"` | no |
| <a name="input_logical_product_service"></a> [logical\_product\_service](#input\_logical\_product\_service) | (Required) Name of the product service for which the resource is created.<br/>    For example, backend, frontend, middleware etc. | `string` | `"grafana"` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether to enable public network access for the managed grafana instance. Defaults to true | `bool` | `true` | no |
| <a name="input_resource_names_map"></a> [resource\_names\_map](#input\_resource\_names\_map) | A map of key to resource\_name that will be used by tf-launch-module\_library-resource\_name to generate resource names | <pre>map(object({<br/>    name       = string<br/>    max_length = optional(number, 60)<br/>  }))</pre> | <pre>{<br/>  "grafana": {<br/>    "max_length": 23,<br/>    "name": "grafana"<br/>  },<br/>  "monitor_workspace": {<br/>    "max_length": 80,<br/>    "name": "amw"<br/>  },<br/>  "resource_group": {<br/>    "max_length": 80,<br/>    "name": "rg"<br/>  },<br/>  "user_managed_identity": {<br/>    "max_length": 80,<br/>    "name": "msi"<br/>  }<br/>}</pre> | no |
| <a name="input_sku"></a> [sku](#input\_sku) | SKU of the managed grafana instance. Possible values are 'Standard' and 'Essential' | `string` | `"Standard"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Custom tags for the Grafana instance | `map(string)` | `{}` | no |
| <a name="input_zone_redundancy_enabled"></a> [zone\_redundancy\_enabled](#input\_zone\_redundancy\_enabled) | Whether to enable zone redundancy for the managed grafana instance. Defaults to false | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Endpoint of the managed grafana instance |
| <a name="output_id"></a> [id](#output\_id) | Resource ID of the managed grafana instance |
| <a name="output_integrated_workspace_ids"></a> [integrated\_workspace\_ids](#output\_integrated\_workspace\_ids) | Azure Monitor workspaces integrated with the grafana instance |
| <a name="output_name"></a> [name](#output\_name) | Name of the managed grafana instance |
| <a name="output_outbound_ip"></a> [outbound\_ip](#output\_outbound\_ip) | Outbound IP of the managed grafana instance if `deterministic_outbound_ip_enabled` is true |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group name of the managed grafana instance |
<!-- END_TF_DOCS -->
