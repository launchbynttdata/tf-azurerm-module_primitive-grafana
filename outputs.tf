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

output "id" {
  description = "The ID of the managed Grafana instance."
  value       = azurerm_dashboard_grafana.grafana.id
}

output "name" {
  description = "The name of the managed Grafana instance."
  value       = azurerm_dashboard_grafana.grafana.name
}

output "endpoint" {
  description = "The endpoint URL of the managed Grafana instance."
  value       = azurerm_dashboard_grafana.grafana.endpoint
}

output "outbound_ip" {
  description = "List of outbound IP addresses when deterministic_outbound_ip_enabled is true."
  value       = azurerm_dashboard_grafana.grafana.outbound_ip
}

output "principal_id" {
  description = "The principal ID of the system-assigned or user-assigned managed identity."
  value       = azurerm_dashboard_grafana.grafana.identity[0].principal_id
}

output "integrated_workspace_ids" {
  description = "List of Azure Monitor workspace resource IDs integrated with this Grafana instance."
  value       = azurerm_dashboard_grafana.grafana.azure_monitor_workspace_integrations[*].resource_id
}
