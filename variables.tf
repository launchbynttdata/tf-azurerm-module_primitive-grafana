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

variable "name" {
  description = "Name of the managed grafana instance to create"
  type        = string
}

variable "resource_group_name" {
  description = "name of the resource group where the managed grafana instance will be created"
  type        = string
}

variable "location" {
  description = "Location where the managed grafana instance will be created"
  type        = string
}

variable "api_key_enabled" {
  description = "Whether to enable API keys for the managed grafana instance. Defaults to false"
  type        = bool
  default     = false
}

variable "deterministic_outbound_ip_enabled" {
  description = "Whether to enable deterministic outbound IP for the managed grafana instance. Defaults to false"
  type        = bool
  default     = false
}

variable "grafana_major_version" {
  description = "Major version of Grafana to deploy"
  type        = string
  default     = "10"

  validation {
    condition     = contains(["9", "10"], var.grafana_major_version)
    error_message = "Major version can be either '9' or '10'"
  }
}

variable "azure_monitor_workspace_ids" {
  description = "List of Azure Monitor workspace IDs to integrate with the managed grafana instance"
  type        = set(string)
  default     = []
}

variable "public_network_access_enabled" {
  description = "Whether to enable public network access for the managed grafana instance. Defaults to true"
  type        = bool
  default     = true
}

variable "sku" {
  description = "SKU of the managed grafana instance. Possible values are 'Standard' and 'Essential'"
  type        = string
  default     = "Standard"

  validation {
    condition     = var.sku == "Standard" || var.sku == "Essential"
    error_message = "Invalid SKU. Possible values are 'Standard' and 'Essential'"
  }
}

variable "zone_redundancy_enabled" {
  description = "Whether to enable zone redundancy for the managed grafana instance. Defaults to false"
  type        = bool
  default     = false
}

variable "identity_ids" {
  description = <<EOT
    Specifies a list of user managed identity ids to be assigned.
  EOT
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Custom tags for the Grafana instance"
  type        = map(string)
  default     = {}
}
