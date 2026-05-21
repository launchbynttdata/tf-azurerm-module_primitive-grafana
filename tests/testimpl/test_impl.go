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

package testimpl

import (
	"context"
	"net/http"
	"os"
	"testing"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/resourcemanager/dashboard/armdashboard"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/launchbynttdata/lcaf-component-terratest/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestGrafana is the functional post-deploy test. It verifies Terraform outputs,
// asserts the Azure-managed Grafana resource is configured as expected via the
// Azure SDK, and exercises the data plane by issuing an HTTP probe against the
// public endpoint.
func TestGrafana(t *testing.T, ctx types.TestContext) {
	assertGrafanaConfiguration(t, ctx)
	exerciseGrafanaEndpoint(t, ctx)
}

// TestGrafanaReadonly is the read-only post-deploy test. It verifies Terraform
// outputs and asserts the Azure-managed Grafana resource via the Azure SDK
// without exercising the data plane or performing any write operations.
func TestGrafanaReadonly(t *testing.T, ctx types.TestContext) {
	assertGrafanaConfiguration(t, ctx)
}

// assertGrafanaConfiguration verifies that the deployed managed Grafana
// instance matches the expected configuration set by examples/complete. It
// cross-checks Terraform outputs against the live state returned by the Azure
// dashboard SDK.
func assertGrafanaConfiguration(t *testing.T, ctx types.TestContext) {
	subscriptionId := os.Getenv("ARM_SUBSCRIPTION_ID")
	require.NotEmpty(t, subscriptionId, "ARM_SUBSCRIPTION_ID must be set")

	opts := ctx.TerratestTerraformOptions()

	resourceId := terraform.Output(t, opts, "id")
	resourceName := terraform.Output(t, opts, "name")
	resourceEndpoint := terraform.Output(t, opts, "endpoint")
	resourceGroupName := terraform.Output(t, opts, "resource_group_name")
	workspaceIds := terraform.OutputList(t, opts, "integrated_workspace_ids")

	require.NotEmpty(t, resourceId, "id output must be non-empty")
	require.NotEmpty(t, resourceName, "name output must be non-empty")
	require.NotEmpty(t, resourceEndpoint, "endpoint output must be non-empty")
	require.NotEmpty(t, resourceGroupName, "resource_group_name output must be non-empty")
	require.Len(t, workspaceIds, 1, "example wires exactly one Azure Monitor workspace integration")

	cred, err := azidentity.NewDefaultAzureCredential(nil)
	require.NoError(t, err, "failed to load Azure default credentials")

	client, err := armdashboard.NewGrafanaClient(subscriptionId, cred, nil)
	require.NoError(t, err, "failed to construct Grafana SDK client")

	resp, err := client.Get(context.Background(), resourceGroupName, resourceName, nil)
	require.NoError(t, err, "Grafana Get call must succeed")

	// Cross-check the resource ID returned by the API matches the Terraform output.
	require.NotNil(t, resp.ID, "API response must include resource ID")
	assert.Equal(t, resourceId, *resp.ID, "API resource ID should match Terraform id output")

	// SKU
	require.NotNil(t, resp.SKU, "SKU must be present on Grafana resource")
	require.NotNil(t, resp.SKU.Name, "SKU.Name must be present")
	assert.Equal(t, "Standard", *resp.SKU.Name, "SKU should match example default")

	// Identity — example uses UserAssigned
	require.NotNil(t, resp.Identity, "Identity must be present")
	require.NotNil(t, resp.Identity.Type, "Identity.Type must be present")
	assert.Equal(t, "UserAssigned", string(*resp.Identity.Type), "identity type should be UserAssigned per example")

	require.NotNil(t, resp.Properties, "Properties must be present on Grafana resource")
	p := resp.Properties

	require.NotNil(t, p.GrafanaMajorVersion, "grafana_major_version must be present")
	assert.Equal(t, "12", *p.GrafanaMajorVersion, "grafana_major_version should match example default")

	require.NotNil(t, p.APIKey, "api_key property must be present — api_key_enabled must be configured")
	assert.Equal(t, "Disabled", string(*p.APIKey), "api_key should be Disabled per example default (api_key_enabled = false)") //nolint:godot // pragma: allowlist secret

	require.NotNil(t, p.PublicNetworkAccess, "public_network_access must be present")
	assert.Equal(t, "Enabled", string(*p.PublicNetworkAccess), "public_network_access should be Enabled per example default")

	require.NotNil(t, p.ZoneRedundancy, "zone_redundancy must be present")
	assert.Equal(t, "Disabled", string(*p.ZoneRedundancy), "zone_redundancy should be Disabled per example default")

	require.NotNil(t, p.DeterministicOutboundIP, "deterministic_outbound_ip must be present")
	assert.Equal(t, "Disabled", string(*p.DeterministicOutboundIP), "deterministic_outbound_ip should be Disabled per example default")

	// Azure Monitor workspace integration — must match the Terraform output.
	require.NotNil(t, p.GrafanaIntegrations, "GrafanaIntegrations must be present")
	integrations := p.GrafanaIntegrations.AzureMonitorWorkspaceIntegrations
	require.Len(t, integrations, 1, "example configures exactly one Azure Monitor workspace integration")
	require.NotNil(t, integrations[0].AzureMonitorWorkspaceResourceID, "integration resource_id must be present")
	assert.Equal(t,
		workspaceIds[0],
		*integrations[0].AzureMonitorWorkspaceResourceID,
		"AMW integration resource_id should match the integrated_workspace_ids Terraform output",
	)

	// Cross-check the endpoint returned by the API matches Terraform output.
	require.NotNil(t, p.Endpoint, "Properties.Endpoint must be present")
	assert.Equal(t, resourceEndpoint, *p.Endpoint, "endpoint from API should match Terraform endpoint output")
}

// exerciseGrafanaEndpoint issues an HTTP GET against the Grafana endpoint to
// confirm the data plane is reachable. This is the write/exercise step that
// differentiates the functional test from the readonly test.
func exerciseGrafanaEndpoint(t *testing.T, ctx types.TestContext) {
	endpoint := terraform.Output(t, ctx.TerratestTerraformOptions(), "endpoint")
	require.NotEmpty(t, endpoint, "endpoint output must be present")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Get(endpoint)
	require.NoError(t, err, "HTTP GET against Grafana endpoint must succeed")
	defer func() { _ = resp.Body.Close() }()

	assert.Truef(t,
		resp.StatusCode >= 200 && resp.StatusCode < 400,
		"Grafana endpoint should return non-error status, got %d", resp.StatusCode,
	)
}
