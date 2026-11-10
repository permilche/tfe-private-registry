variable "tfe_token" {
  description = "TFE API token for authentication"
  type        = string
  sensitive   = true
}

variable "tfe_hostname" {
  description = "TFE hostname for the organization"
  type        = string
}

variable "organization" {
  description = "TFE organization name"
  type        = string
}

variable "vcs_oauth_token_id" {
  description = "OAuth token ID for VCS connection in TFE"
  type        = string
}

variable "private_registry_modules" {
  description = "Map of private registry modules"
  type = map(object({
    # Path of the module inside the repository. Set it when several modules live in the same repository (monorepo).
    # Leave it empty when the module has its own repository and it exists in the root folder.
    source_directory = optional(string)
    # Repository (owner/name) of the module. Defaults to local.modules_repository (see main.tf)
    identifier = optional(string)
    # Name shown in the TFE UI. Defaults to the identifier
    display_identifier = optional(string)
  }))
  default = {}
}
