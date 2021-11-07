package test

import (
	"crypto/tls"
	"fmt"
	"strings"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformCompleteExample(t *testing.T) {
	t.Parallel()

	name := "deso-testing"
	desoPublicHostedZone := "opsy.site"
	expectedDns := name + "." + desoPublicHostedZone

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// website::tag::1::Set the path to the Terraform code that will be tested.
		// The path to where our Terraform code is located
		TerraformDir: "../examples/complete",

		BackendConfig: map[string]interface{}{
			"path": "test-terraform.tfstate",
		},

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name":                    name,
			"deso_public_hosted_zone": desoPublicHostedZone,
			"miner_public_keys":       "BC1YLjDCy9WWFPeyV4J64AhgHNV8KHgvxyAeFvBLGz5nLZTx6Vf1i8x",
			"admin_public_keys":       "BC1YLjDCy9WWFPeyV4J64AhgHNV8KHgvxyAeFvBLGz5nLZTx6Vf1i8x",
			"super_admin_public_keys": "BC1YLjDCy9WWFPeyV4J64AhgHNV8KHgvxyAeFvBLGz5nLZTx6Vf1i8x",
			"support_email":           "dominik.deren@live.com",
		},

		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: true,
	})

	// website::tag::4::Clean up resources with "terraform destroy". Using "defer" runs the command at the end of the test, whether the test succeeds or fails.
	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// website::tag::2::Run "terraform init" and "terraform apply".
	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables
	desoDns := terraform.Output(t, terraformOptions, "deso_dns")

	// website::tag::3::Check the output against expected values.
	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedDns, desoDns)

	// Setup a TLS configuration to submit with the helper, a blank struct is acceptable
	tlsConfig := tls.Config{}

	// Make an HTTP request to the instance and make sure that it responds with a 200 status code.
	url := fmt.Sprintf("https://%s/", desoDns)
	http_helper.HttpGetWithRetryWithCustomValidation(
		t,
		url,
		&tlsConfig,
		60,
		5*time.Second,
		verifyDesoMainPage,
	)
}

func verifyDesoMainPage(statusCode int, body string) bool {
	if statusCode != 200 {
		return false
	}
	return strings.Contains(body, "Welcome to DeSo")
}
