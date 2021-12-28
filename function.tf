# Creating Resource group
resource "azurerm_resource_group" "function-app-test" {
  name     = "function-app-test-rg"
  location = "westus2"
}

# Creating storage account
resource "azurerm_storage_account" "function-app-test" {
  name                     = "functionsapptestsa01"
  resource_group_name      = azurerm_resource_group.function-app-test.name
  location                 = azurerm_resource_group.function-app-test.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Creating App Service Plan for the function app to use
resource "azurerm_app_service_plan" "function-app-test" {
  name                = "azure-functions-test-service-plan"
  location            = azurerm_resource_group.function-app-test.location
  resource_group_name = azurerm_resource_group.function-app-test.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

# Creating Function app
resource "azurerm_function_app" "function-app-test" {
  name                       = "ncmuthu-func-app-test01"
  location                   = azurerm_resource_group.function-app-test.location
  resource_group_name        = azurerm_resource_group.function-app-test.name
  app_service_plan_id        = azurerm_app_service_plan.function-app-test.id
  storage_account_name       = azurerm_storage_account.function-app-test.name
  storage_account_access_key = azurerm_storage_account.function-app-test.primary_access_key
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"    = "https://${azurerm_storage_account.function-app-test.name}.blob.core.windows.net/${azurerm_storage_container.function-app-test.name}/${azurerm_storage_blob.storage_blob.name}${data.azurerm_storage_account_blob_container_sas.storage_account_blob_container_sas.sas}",
    "FUNCTIONS_WORKER_RUNTIME"    = "python",
    "AzureWebJobsDisableHomepage" = "true",
  }
  os_type = "linux"
  version = "~3"
  site_config {
     always_on   = "true"
     elastic_instance_minimum = 1
     linux_fx_version         = "PYTHON|3.7"
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [ data.azurerm_user_assigned_identity.default.id ]
  }
}

# container with private access to keep the package zip
resource "azurerm_storage_container" "function-app-test" {
  name                  = "function-app-test01"
  storage_account_name  = azurerm_storage_account.function-app-test.name
  container_access_type = "private"
}

# zip the directory which has function code
data "archive_file" "function-app-test" {
  type        = "zip"
  source_dir  = "./testfunction01"
  output_path = "testfunction01.zip"
}

# zip file upload to the container. This has the function codes
resource "azurerm_storage_blob" "storage_blob" {
  name = "testfunction01.zip"
  storage_account_name = azurerm_storage_account.function-app-test.name
  storage_container_name = azurerm_storage_container.function-app-test.name
  type        = "Block"
  source      = "testfunction01.zip"
  content_md5 = "${data.archive_file.function-app-test.output_md5}" 
}


# SAS to access the storage to download the zip(package) file
data "azurerm_storage_account_blob_container_sas" "storage_account_blob_container_sas" {
  connection_string = azurerm_storage_account.function-app-test.primary_connection_string
  container_name    = azurerm_storage_container.function-app-test.name

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

# Trigger to restart the function app when the function code is changed
resource "null_resource" "function-app-restart" {
  triggers = {
    src_hash = "${data.archive_file.function-app-test.output_sha}"
  }

  provisioner "local-exec" {
    command = "az functionapp restart --name ncmuthu-func-app-test01 --resource-group function-app-test-rg"
  }
}
