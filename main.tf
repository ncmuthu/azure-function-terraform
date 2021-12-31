# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
}

module "functionapp" {
  source               = "./modules/functionapp"
  function_app_name    = "${var.function_app_name}"
  storage_account_name = "${var.storage_account_name}"
  storage_container_name = "${var.storage_container_name}"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  artifact_output_path = "${var.artifact_output_path}"
}

module "function" {
  source               = "./modules/function"
  source_function_dir  = "${var.source_function_dir}"
  artifact_output_path = "${var.artifact_output_path}"
  function_app_name    = "${var.function_app_name}"
  storage_account_name = "${var.storage_account_name}"
  storage_container_name = "${var.storage_container_name}"
  resource_group_name  = "${var.resource_group_name}"
}
