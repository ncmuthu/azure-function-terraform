data "azurerm_user_assigned_identity" "default" {
  name                = "managed-identity-function-app"
  resource_group_name = "managed-identity"
}
