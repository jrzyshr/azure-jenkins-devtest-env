#! /bin/bash
# az login
# az account set --subscription {subscription-id}
# Variables
resourceGroupName="dtarmtests"
location="eastus2"
echo $resourceGroupName
echo $location
# Create Resource Group
# az group create -l $location -n $resourceGroupName
echo 'Am I here?'

# Create the resource group
echo "Check if resource group already exists"
resourcegroup=$(az group show --name $resourceGroupName)
if [[ $resourcegroup == {* ]]
then
  echo "Resource group already exists"
else
    echo "Create resource group"
    az group create -n $resourceGroupName -l $location
fi


# Deploy Template
#az group deployment create --name ExampleDeployment --resource-group ExampleGroup --template-file c:\MyTemplates\azuredeploy.json
