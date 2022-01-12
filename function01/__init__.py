import logging
import requests
import os
import azure.identity
import azure.keyvault.secrets

from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential

import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    name = req.params.get('name')
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = req_body.get('name')
    keyVaultName = "azncmuthukeyv1"
    KVUri = f"https://{keyVaultName}.vault.azure.net"

    # client_id value is set on the Functionapp Configuration as env variable AZURE_CLIENT_ID
    # credential = DefaultAzureCredential(managed_identity_client_id="cf4cd157-a488-4f16-b714-d56441db1eb3")
    credential = DefaultAzureCredential()
    client = SecretClient(vault_url=KVUri, credential=credential)
    secretName = "test-secret01"
    print(f"Retrieving your secret from {keyVaultName}.")
    retrieved_secret = client.get_secret(secretName)
    print(f"Your secret is '{retrieved_secret.value}'.")


    if name:
        return func.HttpResponse(f"Hello, {name}. This HTTP triggered function executed successfully.Your secret is, {retrieved_secret.value}.")
    else:
        return func.HttpResponse(
             "This HTTP triggered function executed successfully. Please pass a name in the query string or in the request body for a personalized response.",
             status_code=200
        )
