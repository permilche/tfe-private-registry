# TFE Private Registry

> **Disclaimer:** this is a personal project and not an official HashiCorp product. It is not officially supported or maintained by HashiCorp, and I share it to help out the community. It comes "as is", without any warranty. There may be errors, and the Terraform, provider or module versions used here may get deprecated or stop working. Please review and test everything outside production before using it, and use it at your own risk. The repository is public and issues and pull requests are welcome, but I review and validate each one myself, so there is no guaranteed response time, no promise to merge, and no support SLA (see [CONTRIBUTING](.github/CONTRIBUTING.md)). All names, IDs and values are examples or placeholders, so never commit credentials. Terraform, HCP Terraform and Terraform Enterprise are trademarks of HashiCorp.

This repository is part of the **bootstrap and management layer** for Terraform Enterprise (TFE) infrastructure. It belongs to the management layer alongside the `tfe-management` repository.

## Purpose

This repository configures and registers Terraform modules in the TFE Private Registry. It **must be applied first** before the `tfe-management` repository, as `tfe-management` depends on these registered modules for its module invocations.

## Overview

The repository uses Terraform to register the modules of the [`tfe-tf-modules`](https://github.com/permilche/tfe-tf-modules) GitHub repository into the private registry of an HCP Terraform / TFE organization. These modules are then available for use by other Terraform configurations within the organization (for example `tfe-management`).

## Dependencies and Related Repositories

| Repository | Role |
|------------|------|
| [`tfe-tf-modules`](https://github.com/permilche/tfe-tf-modules) | **Hard dependency.** Source of the modules that are registered (the `registry-module` module is also used by this repository itself, downloaded over SSH on `terraform init`) |
| [`tfe-bootstrap`](https://github.com/permilche/tfe-bootstrap) | **Creates the workspace that runs this repository**, with its SSH key and the variables `organization`, `tfe_token`, `tfe_hostname` and `vcs_oauth_token_id` |
| [`tfe-management`](https://github.com/permilche/tfe-management) | Applied **after** this repository. It consumes the registered modules |

## Before You Start: Values to Replace

1. **Module repository.** In [`main.tf`](main.tf) the `source` of the `registry-module` module and `local.modules_repository` (the default repository of the modules) point to `permilche/tfe-tf-modules`. Replace them with your own repository (owner/name). The `source` cannot use variables, so it must be edited by hand. Modules that live in their own repository can set `identifier` instead (see [Important Notes](#important-notes)).
2. **`tfe_hostname`.** Injected by `tfe-bootstrap`: `app.terraform.io` for **HCP Terraform**, or the FQDN of your instance for **self-hosted TFE**.
3. **VCS OAuth connection.** `vcs_oauth_token_id` must belong to a **GitHub** VCS connection that can read the modules repository.
4. **SSH key.** The workspace's SSH key (created by `tfe-bootstrap`) must have read access to the modules repository, because `terraform init` downloads the `registry-module` module over SSH.
5. **Tags.** The registry only shows versions for tags named `<module-name>-<version>` (e.g. `project-1.0.0`) that exist in the modules repository (see [Usage](#usage), step 6). Modules with their own repository use plain `<version>` tags instead.

## Architecture

```
Bootstrap & Management Layer
├── tfe-private-registry (this repo) ← Apply FIRST
└── tfe-management                   ← Apply SECOND (uses modules from private registry)
```

## Registered Modules

This configuration registers the following modules in the TFE Private Registry:

- **agent-pool**: TFE agent pool management
- **dynamic-credentials-azure-configuration**: Azure dynamic credentials (App Registration, federated credentials, role assignment)
- **dynamic-credentials-azure-management**: Azure dynamic credentials for additional workspaces
- **organization-membership**: Organization membership configuration
- **organization-settings**: Organization-level settings
- **policy-set**: Policy set management
- **project**: TFE project configuration
- **registry-module**: Private registry module management
- **run-task**: Run task configuration
- **saml-sso-and-scim**: SAML SSO and SCIM integration
- **ssh-key**: SSH key management
- **team**: Team configuration
- **team-token**: Team token management
- **variable-set**: Variable set configuration
- **vcs-oauth**: VCS OAuth connection setup
- **workspace**: Workspace configuration

## Prerequisites

- Terraform >= 1.0
- TFE API token with appropriate permissions
- VCS OAuth token ID for a GitHub connection
- SSH access to the `tfe-tf-modules` repository (GitHub)

## Configuration

### Required Variables

Create a `terraform.tfvars` file based on `terraform.tfvars.example`:

> `terraform.tfvars` is tracked on purpose, but it only holds `private_registry_modules` (no credentials). `tfe_token`, `tfe_hostname`, `organization` and `vcs_oauth_token_id` are **not** set in the files because this repository is meant to run in TFE after the `tfe-private-registry` workspace is created by `tfe-bootstrap`, which also sets those variables in the workspace.

```hcl
# Only needed for a local run (never commit them; prefer TF_VAR_* environment variables):
# tfe_token          = "your-tfe-api-token"
# tfe_hostname       = "app.terraform.io"  # HCP Terraform; or your TFE FQDN
# organization       = "<organization_name>"
# vcs_oauth_token_id = "your-oauth-token-id"

# Paths are relative to the root of the modules repository
private_registry_modules = {
  "agent-pool" = {
    source_directory = "agent-pool"
  },
  # ... additional modules

  # A module in its own repository (optional, see Important Notes):
  # "my-module" = {
  #   identifier         = "<owner>/<repository>"
  #   display_identifier = "<owner>/<repository>" # optional, defaults to the identifier
  # }
}
```

### Variables

| Variable | Description | Type | Required |
|----------|-------------|------|----------|
| `tfe_token` | TFE API token for authentication | string | Yes |
| `tfe_hostname` | TFE hostname for the organization | string | Yes |
| `organization` | TFE organization name | string | Yes |
| `vcs_oauth_token_id` | OAuth token ID for VCS connection | string | Yes |
| `private_registry_modules` | Map of modules to register. Each one accepts `source_directory`, `identifier` and `display_identifier`, all optional | map(object) | No |

## Usage

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd tfe-private-registry
   ```

2. **Push it to your VCS repository**
   ```bash
   git add .
   git commit -m "my first commit"
   git push origin
   ```

3. **Let the VCS-driven workflow do its magic**

   TFE will run because of a new commit being pushed.

4. **Review the plan**

   To make sure everything is correct.

5. **Apply the configuration**

   Comment if needed and apply the run after validating it. 

6. **Tag and push the modules accordingly**

   After the, you'll be able to see them in the registry, but without any version you won't be able to use them (https://developer.hashicorp.com/terraform/tutorials/modules/module-private-registry-share#create-the-repository). You will need to tag them appropriately and push them so you can use the version argument in the module invocation. Not adding the version argument in the module invocation will make TFE use the latest available version of the module, but it still needs at least one version, so just seeing the module with no version won't work, you need to create at least one version of it to be able to use it.

   ```bash
   git add ./path-to-module
   git commit -m "feature: my first module example"
   git push origin
   git tag module-name-1.0.1
   git push origin module-name-1.0.1 
   ```

7. **Proceed to tfe-management**
   
   After successful application, you can now apply the `tfe-management` repository, which will use the modules registered by this configuration.

## Outputs

- `registry_modules`: Map of registered module names to their IDs

## Module Source

The `registry-module` module is downloaded over SSH from GitHub. The HCP Terraform FQDN (`app.terraform.io`) is **not** used here: this repository is the one that populates the private registry, so it cannot consume it (chicken-and-egg), and a module `source` cannot use variables, which is why it is hardcoded (with a comment in the code):

```
git@github.com:permilche/tfe-tf-modules.git//registry-module?ref=main
```

> **Warning: the source is not pinned to a tag (do not do this in production).** `?ref=main` resolves to the latest commit of the branch on every download, so two applies of the same code are not guaranteed to behave the same. Pin a tag or commit SHA (e.g. `?ref=v1.0.0`) and bump it deliberately. It is left unpinned for simplicity while the modules are being developed. `tfe-tf-modules` does not publish tags for it yet. Once registered, `tfe-management` should set the `version` argument on every registry module.

Each module is configured with:
- VCS repository connection to GitHub (`permilche/tfe-tf-modules` by default, see `local.modules_repository`)
- Specific source directory within the monorepo (`source_directory`)
- Tag-based versioning with module-specific prefixes
- Display identifier for the TFE UI (`display_identifier`, defaults to the repository)

## Important Notes

- **Apply Order**: This repository must be applied **before** `tfe-management`
- **Dependencies**: The `tfe-management` repository depends on these registered modules
- **VCS Integration**: Modules are automatically synced from GitHub using tags. Since we are using the same repository for all the modules, we are specifying the source directory setting to specify the path to the module and then tagging with a prefix to map those modules, check this documentation:
   - https://developer.hashicorp.com/terraform/enterprise/registry/publish-modules#vcs-provider-settings
   - https://developer.hashicorp.com/terraform/enterprise/registry/publish-modules#release-tag-prefixes
   - https://developer.hashicorp.com/terraform/enterprise/workspaces/settings/vcs#trigger-runs-when-a-git-tag-is-published
- **Versioning**: As mentioned, each module uses tag-based versioning with a module-specific prefix
- **Monorepo, but not only**: this example keeps all the modules in one repository, one folder per module. The `registry-module` module also supports one repository per module, and so does this configuration. For those modules set `identifier` (and optionally `display_identifier`) in `private_registry_modules` and leave `source_directory` out (the module is then expected in the root folder of its repository). Without a `source_directory` the tag prefix is not applied, so the module is versioned with plain tags (`1.0.0`) instead of `<module-name>-1.0.0`. The repository must be reachable with the same VCS OAuth connection (`vcs_oauth_token_id`).
- **Tags and branch**: the `vcs_repo` block hardcodes `tags = true` and does not set a `branch`, so modules are published from tags, and the repository's default branch is the one used. This behavior can be tuned (for example by setting a `branch`, or by not publishing by tags), but it is left as is here. The `registry-module` module already accepts those settings in its `vcs_repo` object, so tuning it means editing the `vcs_repo` block in [`main.tf`](main.tf) (and, if you want it per module, adding the attributes to `private_registry_modules`).

## Maintenance

To add a new module to the private registry:

1. Add the module definition to `terraform.tfvars`:
   ```hcl
   private_registry_modules = {
     "new-module" = {
       source_directory = "new-module"
     }
   }
   ```

   For a module that has its own repository, set the repository instead of the directory:
   ```hcl
   private_registry_modules = {
     "other-module" = {
       identifier = "<owner>/<repository>"
     }
   }
   ```

2. Commit, tag it and push it to the VCS repository:
   ```bash
   git add ./path-to-module
   git commit -m "feature: added support for this new feature (example)"
   git push origin
   git tag module-name-1.0.1
   git push origin module-name-1.0.1 
   ```

## Security

- The `tfe_token` variable is marked as sensitive
- Store credentials securely (e.g., using environment variables or a secrets manager)
- `terraform.tfvars` is tracked and must only contain the module list. Never add tokens or other credentials to it
- `.terraform*`, state files and `.bob/` are git-ignored

## Support

This project is offered as is and **no support is provided** (see the disclaimer at the top of this README and [SUPPORT](.github/SUPPORT.md)). For issues or questions, these resources are the best place to start:

- The [`registry-module` module documentation](https://github.com/permilche/tfe-tf-modules/tree/main/registry-module)
- [TFE documentation](https://developer.hashicorp.com/terraform/enterprise)
- [TFE provider documentation](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs)
- [Publishing modules to the private registry](https://developer.hashicorp.com/terraform/enterprise/registry/publish-modules)

## License

Licensed under the [Mozilla Public License 2.0](LICENSE). See also [CONTRIBUTING](.github/CONTRIBUTING.md), [SUPPORT](.github/SUPPORT.md) and [SECURITY](.github/SECURITY.md).
