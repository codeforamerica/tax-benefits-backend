# Create a New Configuration

Although you can create a configuration from scratch, it may be easier to start
with an existing configuration and modify it to suit your needs. This guide will
walk you through creating a new configuration based on an existing one.

## Copy the existing configuration

Choose a configuration that is similar to the one you want to create. For this
example, we'll create a new staging environment.

Start by copying the current configuration, ignoring installed dependencies:

```bash
rsync -a --exclude '.terraform*' \
  tofu/config/staging.fileyourstatetaxes.org/ \
  tofu/config/staging.my-project.org/
```

## Update the configuration

Start by updating any references to the old configuration. This includes, at a
minimum, the following:

- `project` and `environment` tags in `providers.tf`
- `key` under the backend configuration in `main.tf`
- `project` and `environment` in `main.tf` (multiple references)
- `log_groups` name and tags under the `logging` module in `main.tf`
- `domain`, `aptible_environment`, and `aptible_app_id` under the `waf` module
  in `main.tf`

Make any additional changes necessary for your new configuration.

## Initialize & plan

After updating, you can initialize the configuration and plan the changes:

```bash
tofu init
tofu plan -o tfplan.out
```

Follow the [getting started][usage] documentation for more information on
planning and applying changes.

[usage]: getting-started.md
