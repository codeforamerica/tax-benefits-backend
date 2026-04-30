# Gyraffe Staging Configuration

This configures and manages the tofu (or terraform) backend for [Gyraffe](https://github.com/codeforamerica/gyraffe) staging environment

We utilize several [tofu modules](https://github.com/codeforamerica/tofu-modules?tab=readme-ov-file)
- [AWS Backend](https://github.com/codeforamerica/tofu-modules-aws-backend)
- In [Gyraffe module](https://github.com/codeforamerica/tax-benefits-backend/tree/main/tofu/modules/gyraffe)
  - [AWS Fargate Service Module](https://github.com/codeforamerica/tofu-modules-aws-fargate-service)
  - [AWS VPC Module](https://github.com/codeforamerica/tofu-modules-aws-vpc)
  - [AWS Secrets Module](https://github.com/codeforamerica/tofu-modules-aws-secrets)
  - [AWS Serverless DB Module](https://github.com/codeforamerica/tofu-modules-aws-serverless-database)
  - [AWS Logging Module](https://github.com/codeforamerica/tofu-modules-aws-logging)

## Running

You may need to set up OpenTofu and set up your `AWS_PROFILE` in order to run `tofu init` and `tofu plan`.
You can read the [set up walkthrough here](https://www.notion.so/cfa/Setting-up-new-tax-benefits-backend-infrastructure-using-OpenTofu-200373fd79b2809cab2fc8c0eead8d1a?source=copy_link#200373fd79b280ce8b43c466ec7093e5).
This configuration uses the [shared Gyraffe module](https://github.com/codeforamerica/tax-benefits-backend/tree/main/tofu/modules/gyraffe).

### Updates

- Make updates to the `main.tf`, `providers.tf`, `variables.tf`, `versions.tf` as needed.
  - Most of the `main.tf` utilizes the [gyraffe module](https://github.com/codeforamerica/tax-benefits-backend/tree/main/tofu/modules/gyraffe), which require some variables. Please read the [Gyraffe module README](https://github.com/codeforamerica/tax-benefits-backend/tree/add-read-me/tofu/modules/gyraffe) for more information.
    - domain
    - environment
    - cidr
    - private_subnets
    - public_subnets
- If you are utilizing new modules, make sure to use `moved.tf` to tell OpenTofu that these resources have moved and where they can now be found by using a series of `moved` blocks.
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
  - Environment to deploy to: `gyraffe-nonprod` (for staging, `gyraffe-prod` for production)
  - The OpenTofu configuration to plan: `staging.gyraffe.getyourrefund.org` (`gyraffe.getyourrefund.org` for production)
- More often, the deploy action will run as a result of updates on [`gyraffe` repository](https://github.com/codeforamerica/gyraffe)
  and the subsequent GitHub deploy actions [which trigger the deploy action on gyraffe infrastructure](https://github.com/codeforamerica/gyraffe/blob/main/.github/workflows/deploy-to-staging.yml#L84-L98).
