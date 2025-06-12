# PYA Staging Configuration

This configures and manages the tofu (or terraform) backend for [Prior Year Access (PYA)](https://github.com/codeforamerica/pya) staging environment

## Running

This configuration uses the [shared PYA module](https://github.com/codeforamerica/tax-benefits-backend/tree/main/tofu/modules/pya).

### Updates

- Make updates to the `main.tf`, `providers.tf`, `variables.tf`, `versions.tf` as needed.
- If you are utilizing new modules, make sure to use `moved.tf` to tell OpenTofu that these resources have moved and where they can now be found by using a series of `moved` blocks.
Updates can be applied as usual with `tofu plan` and `tofu apply`.
- `tofu plan`: **always review the changes you are making to the configuration**. Have the reviewer also confirm the changes before they approve the pull request.
  - if the list of changes are too long, you can do `tofu plan > plan.out` which should add a `plan.out` file locally which you can share as a [gist](https://gist.github.com/) with a colleague.
  - if you're not sure what the changes you are seeing are, **make sure to reach out to confirm with someone what the changes are**
- Unless you are spinning up a new environment and do not currently have deploy actions set up, do NOT run `tofu apply` from a local branch. The `tofu apply` should run the plan shown in `tofu plan` in the appropriate deploy action.
- To run `tofu apply` and actually make changes to the infrastructure, merge in the approved PR with the changes, and run [the `deploy` github workflow](https://github.com/codeforamerica/tax-benefits-backend/actions/workflows/deploy.yaml).
  - Use workflow from: `main`
  - Environment to deploy to: `pya-nonprod`
  - The OpenTofu configuration to plan: `staging.pya.fileyourstatetaxes.org`
