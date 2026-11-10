output "registry_modules" {
  value = {
    for key, module in module.registry_tfe_modules : key => module.id
  }
}