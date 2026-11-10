locals {
  # GitHub repository (owner/name) that holds the modules by default. Update it to your own tfe-tf-modules repository
  modules_repository = "permilche/tfe-tf-modules"
}

module "registry_tfe_modules" {
  for_each = var.private_registry_modules
  source   = "git@github.com:permilche/tfe-tf-modules.git//registry-module?ref=main" # IMPORTANT: cannot use variables in module sources, so this must be hardcoded; update it to your own tfe-tf-modules repository. Not pinned to a tag for simplicity (pin a tag, e.g. ?ref=v1.0.0, in production)

  organization    = var.organization
  name            = each.key
  module_provider = "tfe"

  vcs_repo = {
    # Monorepo by default. A module can set its own identifier (and display_identifier) to live in its own repository
    display_identifier = coalesce(each.value.display_identifier, each.value.identifier, local.modules_repository)
    identifier         = coalesce(each.value.identifier, local.modules_repository)
    oauth_token_id     = var.vcs_oauth_token_id
    source_directory   = each.value.source_directory
    tags               = true
    # The prefix maps tags to modules inside a monorepo (<module>-1.0.0). A module with its own repository uses plain tags (1.0.0)
    tag_prefix = each.value.source_directory != null ? "${each.key}-" : null
  }
}
