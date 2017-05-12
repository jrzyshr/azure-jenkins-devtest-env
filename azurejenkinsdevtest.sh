#! /bin/bash

az login
az account set --subscription {subscription-id}

az group create --name ExampleGroup --location "Central US"
az group deployment create --name ExampleDeployment --resource-group ExampleGroup --template-file c:\MyTemplates\azuredeploy.json