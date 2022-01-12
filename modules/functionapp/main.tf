# Creating Resource group
resource "azurerm_resource_group" "function-app-test" {
  name     = "${var.resource_group_name}"
  location = "westus2"
}

# Creating storage account
resource "azurerm_storage_account" "function-app-test" {
  name                     = "${var.storage_account_name}"
  resource_group_name      = "${var.resource_group_name}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  #network_rules {
    #default_action             = "Deny"
    #ip_rules                   = ["132.188.71.3", "203.202.234.0/24", "40.64.128.224", "40.64.107.98", "40.64.107.100", "40.64.107.105", "40.64.107.106", "40.64.107.203", "40.64.107.211", "40.64.128.224"]
  #}
  depends_on = [
    azurerm_resource_group.function-app-test,
  ]

}

# container with private access to keep the package zip
resource "azurerm_storage_container" "function-app-test" {
  name                  = "${var.storage_container_name}"
  storage_account_name  = "${var.storage_account_name}"
  container_access_type = "private"
}

# SAS to access the storage to download the zip(package) file
data "azurerm_storage_account_blob_container_sas" "storage_account_blob_container_sas" {
  connection_string = azurerm_storage_account.function-app-test.primary_connection_string
  container_name    = "${var.storage_container_name}"

  start = "2021-11-01T00:00:00Z"
  expiry = "2022-11-01T00:00:00Z"

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}


# Creating App Service Plan for the function app to use
resource "azurerm_app_service_plan" "function-app-test" {
  name                = "azure-functions-test-service-plan"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

# Enabling App Insights
resource "azurerm_application_insights" "function-app-test" {
  name                = "${var.function_app_name}-appinsights"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  application_type    = "web"
}

# Managed identity creation
resource "azurerm_user_assigned_identity" "managed_identity" {
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  name                = "${var.function_app_name}_managed_identity"
}
# Adding role assignemnt for the managed identity
resource "azurerm_role_assignment" "managed_identity" {
  scope                = azurerm_user_assigned_identity.managed_identity.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.managed_identity.principal_id
}

# Creating Function app
resource "azurerm_function_app" "function-app-test" {
  name                       = "${var.function_app_name}"
  location                   = "${var.location}"
  resource_group_name        = "${var.resource_group_name}"
  app_service_plan_id        = azurerm_app_service_plan.function-app-test.id
  storage_account_name       = "${var.storage_account_name}"
  storage_account_access_key = azurerm_storage_account.function-app-test.primary_access_key
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"       = "https://${azurerm_storage_account.function-app-test.name}.blob.core.windows.net/${azurerm_storage_container.function-app-test.name}/${var.artifact_output_path}${data.azurerm_storage_account_blob_container_sas.storage_account_blob_container_sas.sas}",
    "FUNCTIONS_WORKER_RUNTIME"       = "python",
    "AzureWebJobsDisableHomepage"    = "true",
    "APPINSIGHTS_INSTRUMENTATIONKEY" = "${azurerm_application_insights.function-app-test.instrumentation_key}"
  }
  os_type = "linux"
  version = "~3"
  site_config {
     linux_fx_version         = "PYTHON|3.6"
     ftps_state               = "FtpsOnly"
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [ azurerm_user_assigned_identity.managed_identity.id ]
  }
}
