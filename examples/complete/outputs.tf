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
  description = "Resource ID of the managed grafana instance"
  value       = module.grafana.id
}

output "name" {
  description = "Name of the managed grafana instance"
  value       = module.grafana.name
}

output "resource_group_name" {
  description = "Resource group name of the managed grafana instance"
  value       = module.resource_group.name
}

output "integrated_workspace_ids" {
  description = "Azure Monitor workspaces integrated with the grafana instance"
  value       = module.grafana.integrated_workspace_ids
}
