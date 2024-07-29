locals {
  grafana_name        = module.resource_names["grafana"].minimal_random_suffix_without_any_separators
  resource_group_name = module.resource_names["resource_group"].minimal_random_suffix
}
