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

resource "azurerm_dashboard_grafana" "grafana" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  api_key_enabled                   = var.api_key_enabled
  deterministic_outbound_ip_enabled = var.deterministic_outbound_ip_enabled
  public_network_access_enabled     = var.public_network_access_enabled
  grafana_major_version             = var.grafana_major_version
  zone_redundancy_enabled           = var.zone_redundancy_enabled
  sku                               = var.sku

  dynamic "azure_monitor_workspace_integrations" {
    for_each = var.azure_monitor_workspace_ids

    content {
      resource_id = azure_monitor_workspace_integrations.key
    }
  }

  identity {
    type         = var.identity_ids != null ? "UserAssigned" : "SystemAssigned"
    identity_ids = var.identity_ids
  }

  tags = local.tags
}
