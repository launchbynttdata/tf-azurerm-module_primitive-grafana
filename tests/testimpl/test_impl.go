package testimpl

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/launchbynttdata/lcaf-component-terratest/types"
	"github.com/stretchr/testify/assert"
)

func TestGrafana(t *testing.T, ctx types.TestContext) {
	subscriptionId := os.Getenv("ARM_SUBSCRIPTION_ID")
	if len(subscriptionId) == 0 {
		t.Fatal("ARM_SUBSCRIPTION_ID environment variable is not set")
	}

	resourceId := terraform.Output(t, ctx.TerratestTerraformOptions(), "id")
	workspaceIds := terraform.OutputList(t, ctx.TerratestTerraformOptions(), "integrated_workspace_ids")

	t.Run("TfOutputsNotEmpty", func(t *testing.T) {
		assert.NotEmpty(t, resourceId, "Grafana resource ID must not be empty")
		assert.NotEmpty(t, workspaceIds, "Workspace IDs must not be empty")
	})
}
