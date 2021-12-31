# zip the directory which has function code
data "archive_file" "function-app-test" {
  type        = "zip"
  source_dir  = "${var.source_function_dir}"
  output_path = "${var.artifact_output_path}"
}

# zip file upload to the container. This has the function codes
resource "azurerm_storage_blob" "storage_blob" {
  name = "${var.artifact_output_path}"
  storage_account_name   = "${var.storage_account_name}"
  storage_container_name = "${var.storage_container_name}"
  type        = "Block"
  source      = "${var.artifact_output_path}"
  content_md5 = "${data.archive_file.function-app-test.output_md5}"
}

# Trigger to restart the function app when the function code is changed
resource "null_resource" "function-app-restart" {
  triggers = {
    src_hash = "${data.archive_file.function-app-test.output_sha}"
  }

  provisioner "local-exec" {
    command = "az functionapp restart --name '${var.function_app_name}' --resource-group '${var.resource_group_name}'"
  }

  depends_on = [
    azurerm_storage_blob.storage_blob,
  ]

}

