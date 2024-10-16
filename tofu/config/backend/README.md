# Backend Configuration

This configures and manages the tofu (or terraform) backend for Tax Benefits
projects. Since Tax Benefits uses a single AWS account, we configure and use
a single backend for all environments.

## Running

This configuration uses the [shared AWS backend module][backend-module].

### First run

The initial run of this configuration must be done _before_ the
`terraform.backend` configuration is added:

```bash
tofu init
tofu plan -out backend.tfplan
# Make sure to review the plan before applying!
tofu apply backend.tfplan
rm backend.tfplan
```

Add the `terraform.backend` configuration and run the following to migrate the
state file.

```bash
tofu init -migrate-state
rm terraform.tfstate terraform.tfstate.backup
```

### Updates

Updates can be applied as usual with `tofu plan` and `tofu apply`.

[backend-module]: https://github.com/codeforamerica/tofu-modules-aws-backend
