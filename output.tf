output "function_app_name" {
  value = azurerm_function_app.function-app-test.name
  description = "Deployed function app name"
}

output "function_app_default_hostname" {
  value = azurerm_function_app.function-app-test.default_hostname
  description = "Deployed function app hostname"
}