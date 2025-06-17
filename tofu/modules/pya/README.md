# PYA Module

This module creates the necessary resources for [Prior Year Access (PYA)](https://github.com/codeforamerica/pya)
staging/production environment using OpenTofu.
We utilize several [tofu modules](https://github.com/codeforamerica/tofu-modules?tab=readme-ov-file)
- [AWS Fargate Service Module](https://github.com/codeforamerica/tofu-modules-aws-fargate-service)
- [AWS VPC Module](https://github.com/codeforamerica/tofu-modules-aws-vpc)
- [AWS Secrets Module](https://github.com/codeforamerica/tofu-modules-aws-secrets)
- [AWS Serverless DB Module](https://github.com/codeforamerica/tofu-modules-aws-serverless-database)
- [AWS Logging Module](https://github.com/codeforamerica/tofu-modules-aws-logging)
- [S3 bucket for storing the archived submission_pdfs](https://search.opentofu.org/provider/hashicorp/aws/latest/docs/resources/s3_bucket)

## Usage

Add this module to your `main.tf` (or appropriate) file and configure the inputs
to match your desired configuration. For example, to set up a new pya environment,
you may use something like the following:

```hcl
module "pya" {
  source = "../../modules/pya"

  environment         = "demo"
  # Ideally you should have the domain / cidr / private_subnets / public_subnets already avilable to plug in
  # The values below are dummy values and should not be used.
  domain              = "new-app.org"
  cidr                = "12.3.45.0/22"
  private_subnets     = ["12.3.47.0/26", "12.3.47.64/26", "12.3.47.128/26"]
  public_subnets      = ["12.3.45.0/26", "12.3.45.64/26", "12.3.45.128/26"]
}
```

Make sure you are in the correct `/config` folder before running any tofu commands
with the correct `AWS_PROFILE` set in your shell (`.zshrc`, `.bash_profile`, etc).

Make sure you run `tofu init` after adding the module to your configuration,
then plan your configuration to see the changes that would be applied:

```bash
tofu init
tofu plan
```

> [!IMPORTANT]
>  Currently this module is designed for use for `staging.pya.fileyourstatetaxes.org` (staging)
and `pya.fileyourstatetaxes.org` (production).
Any changes made to the module will be reflected in the configurations of those environments
and should be reviewed closely.

- `tofu plan`: **always review the changes you are making to the configuration**.
   Have the reviewer also confirm the changes before they approve the pull request.
  - if the list of changes are too long, you can do `tofu plan > plan.out`
    which should add a `plan.out` file locally which you can share as a [gist](https://gist.github.com/) with a colleague.
  - if you're not sure what the changes you are seeing are,
    **make sure to reach out to confirm with someone what the changes are**
- Unless you are spinning up a new environment and do not currently have deploy actions set up,
  **do NOT run `tofu apply` from a local branch**. The `tofu apply` should run the plan shown in
  `tofu plan` in the appropriate deploy action.
- To run `tofu apply` and actually make changes to the infrastructure,
  merge in the approved PR with the changes, and run [the `deploy` github workflow](https://github.com/codeforamerica/tax-benefits-backend/actions/workflows/deploy.yaml).
  - Use workflow from: `main`
  - Environment to deploy to: `pya-nonprod` (for staging, `pya-prod` for production)
  - The OpenTofu configuration to plan: `staging.pya.fileyourstatetaxes.org` (`pya.fileyourstatetaxes.org` for production)
- More often, the deploy action will run as a result of updates on [`pya` repository](https://github.com/codeforamerica/pya)
  and the subsequent GitHub deploy actions [which trigger the deploy action on pya infrastructure](https://github.com/codeforamerica/pya/blob/main/.github/workflows/deploy-to-staging.yml#L84-L98).
