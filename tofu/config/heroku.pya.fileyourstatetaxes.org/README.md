# PYA Heroku Configuration

This configures and manages the tofu (or terraform) backend for [Prior Year Access (PYA)](https://github.com/codeforamerica/pya) heroku environment

We utilize several [tofu modules](https://github.com/codeforamerica/tofu-modules?tab=readme-ov-file)
- [AWS Backend](https://github.com/codeforamerica/tofu-modules-aws-backend)
- [AWS Logging Module](https://github.com/codeforamerica/tofu-modules-aws-logging)

We add a S3 bucket in the s3.tf file (`heroku_submission_pdfs` resource). The rest of the infrastructure is set up by heroku.
See [documentation about Heroku Review Apps](https://devcenter.heroku.com/articles/github-integration-review-apps) for the infrastructure set up.

## Running

You may need to set up OpenTofu and set up your `AWS_PROFILE` in order to run `tofu init` and `tofu plan`.
You can read the [set up walkthrough here](https://www.notion.so/cfa/Setting-up-new-tax-benefits-backend-infrastructure-using-OpenTofu-200373fd79b2809cab2fc8c0eead8d1a?source=copy_link#200373fd79b280ce8b43c466ec7093e5).
This configuration uses the [shared PYA module](https://github.com/codeforamerica/tax-benefits-backend/tree/main/tofu/modules/pya).

### Updates

- Make updates to the `main.tf`, `providers.tf`, `variables.tf`, `versions.tf` as needed.
Updates can be applied as usual with `tofu plan` and `tofu apply`.
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
  - The OpenTofu configuration to plan: `heroku.pya.fileyourstatetaxes.org`
