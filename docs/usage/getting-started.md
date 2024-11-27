---
# Make sure this is the first page in the navigation order.
weight: -1
---
# Getting Started

Before you can begin, you must have the following prerequisites installed:

> [!TIP]
> It can be useful to place any required environment variables, such as
> `AWS_PROFILE` in a `.env` file. You can find a [sample `.env`][sample-env]
> file in the root of the repository.
>
> This file can be sourced using `source .env` or by using a tool like
> [oh-my-zsh][omz], and will be ignored by version control.

- [AWS CLI][aws-cli]
- [OpenTofu]
- [Aptible CLI][aptible-cli]
- `AWS_PROFILE` should be set to the appropriate [AWS profile][aws-profile] for
  authentication
- An [SSO token][aptible-sso] for Aptible has been set

## Planning & applying changes

Before applying changes to an environment, it is recommended to plan the changes
first. This is to ensure that the changes are as expected and to avoid any
unintended consequences.

> [!NOTE]
> For the following examples, we'll use the `staging.fileyourstatetaxes.org`
> configuration. Replace this with the appropriate configuration directory.
>
> All commands should be run from the configuration directory.

First, we'll need to move to the configuration directory and make sure it's
initialized.

```bash
cd tofu/config/staging.fileyourstatetaxes.org
tofu init
```

This will install the pinned dependencies for the configuration and set up the
backend to read and write state.

Now we can plan the changes. This will show us all resources that are expected
to be **created**, **updated**, **destroyed**, or **replaced**, and save the
plan to an output file (`tfplan.out`). When we apply the changes, we'll use this
file to make sure it only applies the changes we've planned.

```bash
tofu plan -o tfplan.out
```

Review the plan output. Make sure to review the changes closely, to ensure that
they are as expected.

> [!CAUTION]
> Some resource updates may require that a resource be replaced. This can lead
> to data loss or downtime. Make sure to review the plan output carefully.

Once you're satisfied with the plan, you can apply the changes.

```bash
tofu apply tfplan.out
```

This will output the changes that are being made, and prompt you to confirm that
you want to apply the changes. If you're sure, type `yes` and press `Enter`.

> [!TIP]
> You must type `yes` to apply changes. `y` or any variation thereof will not
> be accepted and will result in your apply being canceled.

Depending on the changes being made, this may take some time. Keep an eye on the
output to ensure that the changes are being applied as expected and there are no
unforeseen issues.

## Updating dependencies.

You can update the dependencies for the configuration by passing the `-upgrade`
flag to `tofu init`. This will also update the versions pinned in
`.terraform.lock.hcl`, which should be checked into version control.

```bash
tofu init -upgrade
```

[aptible-cli]: https://www.aptible.com/docs/reference/aptible-cli/overview
[aptible-sso]: https://www.aptible.com/docs/core-concepts/security-compliance/authentication/sso#cli-token-for-sso
[aws-cli]: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html
[aws-profile]: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-authentication.html
[omz]: https://ohmyz.sh/
[opentofu]: https://opentofu.org/docs/intro/install/
