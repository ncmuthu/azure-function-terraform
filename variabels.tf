variable "resource_group_name" {
  description = "Resource group name"
}

variable "location" {
  description = "location where to create resources"
  default     = "westus2"
}

variable "storage_account_name" {
  description = "Storage account name"
}

variable "source_function_dir" {
  description = "Source function directory"
}

variable "artifact_output_path" {
  description = "file name of the zip of function"
}

variable "function_app_name" {
  description = "Function App Name"
}

variable "storage_container_name" {
  description = "Storage container name"
}

