package testimpl

import "github.com/launchbynttdata/lcaf-component-terratest/types"

type ThisTFModuleConfig struct {
	types.GenericTFModuleConfig
	// No module-specific test configuration; the grafana primitive's behavior is
	// verified via Terraform outputs and the Azure dashboard SDK.
}
