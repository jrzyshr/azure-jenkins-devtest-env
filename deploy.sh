#!/bin/bash

if [[ -n $1 ]]; 
then
    resourceGroupName=$1
else
    echo "Resource group name not specified"
    exit 1
fi

# Subscription details
subscriptionid="cbd08660-392c-42f2-a859-921607be1e41"
location="eastus"

# Network details
# Disabled due to bug https://github.com/Azure/acs-engine/issues/120
#vNetName="ContainerVNET"
#subnet1Name="ContainerSubnet"
#vNetaddressPrefix="172.23.0.0/16"
#subnet1addressPrefix="172.23.0.0/16"

# VPN Gateway Details
gatewayName="$resourceGroupName-vpn"
gatewayPublicIpAddressName="$resourceGroupName-vpn-ip"
gatewaySubnetname='GatewaySubnet'
gatewaySubnetAddressPrefix="10.241.0.0/24"
gatewaySku='Basic'
gatewayType='Vpn'
gatewayVpnType='RouteBased'

# SQL DB details
sqlAdministratorLogin="installer"
sqlAdministratorLoginPassword="V@rian01V@rian01"
sqlServerName="$resourceGroupName-sql"
databaseName="ProductDB"
fwExceptionStartIP="10.240.0.1"
fwExceptionEndIP="10.240.255.254"

# Container Service details
linuxAdmin="azureuser"
firstConsecutiveStaticIP="10.240.255.245"
masterSubnetId="/subscriptions/$subscriptionid/resourceGroups/$resourceGroupName/providers/Microsoft.Network/virtualNetworks/$vNetName/subnets/$subnet1Name"
dnsName="$resourceGroupName-acs"
acsName="ContainerService-$resourceGroupName"
acsStorageAccountName="acspsa$resourceGroupName"
acsStorageAccountSku="Standard_LRS"
agentSize="Standard_A3"
masterCount=1
agentCount=2

################################################################
# Script begins here
################################################################
echo "Starting script"
az account set --subscription $subscriptionid

echo "Check if compile directory already exists"
compileDir="compiled/kubernetes-$resourceGroupName"
if [ -d "compiled/" ]
then
    echo "Compile directory already exists"
else
    echo "Create compile directory"
    mkdir "compiled/"
fi

if [ -d "$compileDir/" ]
then
    echo "Resource group compile directory already exists"
else
    echo "Create resource group compile directory"
    mkdir "$compileDir/"
fi

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

# Create the service principal
echo "Check if service principal already exists"
if [ -f serviceprincipal.json ]
then
    echo "serviceprincipal.json already exists"
    echo "remove this file to create a new service principal"
else
    echo "Create service principal"
    az ad sp create-for-rbac --role "Contributor" --scopes "/subscriptions/$subscriptionid/resourceGroups/$resourceGroupName" >> serviceprincipal.json
fi

# Load the service principal details
echo "Load service principal details"
servicePrincipalName=$(jq -r .name serviceprincipal.json)
servicePrincipalSecret=$(jq -r .password serviceprincipal.json)

# Load the SSH key created earlier - see README
echo "Load SSH key"
sshKey=$(cat ~/.ssh/id_rsa.pub)

# Create the container service
echo "Check if Container Service already exists"
acs=$(az acs show --resource-group $resourceGroupName --name $acsName)
if [[ $acs == {* ]]
then
    echo "Container Service already exists"
else
    echo "Create container service"
    az acs create --name $acsName --resource-group $resourceGroupName --dns-prefix $dnsName --orchestrator-type Kubernetes --agent-vm-size $agentSize --agent-count $agentCount --master-count $masterCount --client-secret $servicePrincipalSecret --service-principal $servicePrincipalName
    #az acs create --name $acsName --resource-group $resourceGroupName --dns-prefix $dnsName --orchestrator-type Kubernetes --client-secret $servicePrincipalSecret --service-principal $servicePrincipalName
fi
          
# Create persistent storage for the container service
echo "Check if storage account already exists"
storage=$(az storage account show --resource-group $resourceGroupName --name $acsStorageAccountName) 
if [[ $storage == {* ]]
then
    echo "Storage account already exists"
else
    echo "Create storage account"
    az storage account create --resource-group $resourceGroupName --location $location --name $acsStorageAccountName --sku $acsStorageAccountSku
fi

# get the access key for the storage account
#storageAccountKey=$(az storage account keys list --resource-group $resourceGroupName --account-name $acsStorageAccountName | jq -r '.keys[0].value')

# Create container for the VHDs
# echo "Check if storage container already exists"
# container=$(az storage container show --name vhds --account-key $storageAccountKey --account-name $acsStorageAccountName) 
# if [[ $container == {* ]]
# then
#     echo "Storage container already exists"
# else
#     echo "Create storage container"
#     az storage container create --name vhds --account-key $storageAccountKey --account-name $acsStorageAccountName
# fi

# TODO: Add gateway subnet
echo "Check if virtual network has a gateway subnet"
vNetList=$(az network vnet list --resource-group $resourceGroupName)
vNetName=$(echo $vNetList | jq -r '.[] | .name')
gatewaySubnet=$(az network vnet subnet show --resource-group $resourceGroupName --vnet-name $vNetName --name 'GatewaySubnet')
if [[ $gatewaySubnet == {* ]]
then
    echo "Virtual network has a gateway subnet"
else
    echo "Create gateway subnet for virtual network"
    #TODO: add network-security-group
    az network vnet subnet create --address-prefix $gatewaySubnetAddressPrefix --name 'GatewaySubnet' --resource-group $resourceGroupName --vnet-name $vNetName
fi

# VPN PIP
echo "Check if VPN PIP exists"
vpnPip=$(az network public-ip show --resource-group $resourceGroupName --name $gatewayPublicIpAddressName)
if [[ $vpnPip == {* ]]
then
    echo "VPN PIP exists"
else
    echo "Create VPN PIP"
    #az network public-ip create --name $gatewayPublicIpAddressName --resource-group $resourceGroupName --dns-name $gatewayName
fi

# VPN
echo "Check if VPN gateway exists"
# vpnGateway=$(az network vpn-gateway show --resource-group $resourceGroupName --name $gatewayName)
# if [[ $vpnGateway == {* ]]
# then
#     echo "VPN gateway exists"
# else
#     echo "Create VPN gateway"
#     #az network vpn-gateway create --name $gatewayName --public-ip-address $gatewayPublicIpAddressName --resource-group $resourceGroupName --vnet $vNetName --gateway-type $gatewayType --sku $gatewaySku --vpn-type $gatewayVpnType
# fi

# Create the SQL database
echo "Check if SQL database already exists"
sql=$(az resource show --id "/subscriptions/$subscriptionid/resourceGroups/$resourceGroupName/providers/Microsoft.Sql/servers/$sqlServerName/databases/$databaseName") 
if [[ $sql == {* ]]
then
    echo "SQL database already exists"
else
    echo "Create SQL database"
    az group deployment create --resource-group $resourceGroupName --template-file templates/sqldeploy.json --parameters "{\"sqlAdministratorLogin\": {\"value\": \"$sqlAdministratorLogin\"},\"sqlAdministratorLoginPassword\": {\"value\": \"$sqlAdministratorLoginPassword\"},\"sqlServerName\": {\"value\": \"$sqlServerName\"},\"databaseName\": {\"value\": \"$databaseName\"},\"fwExceptionStartIP\": {\"value\": \"$fwExceptionStartIP\"},\"fwExceptionEndIP\": {\"value\": \"$fwExceptionEndIP\"}}"    
fi

echo "Check if SQL is connected to the VPN gateway"

echo ""
echo "################################################################################################################"
echo ""
echo "All Done"
echo ""
echo "To SSH into the Kubernetes master:"
echo "    ssh $linuxAdmin@$dnsName.$location.cloudapp.azure.com"
echo ""
echo "To get the Kubernetes credentials:"
echo "    az acs kubernetes get-credentials --dns-prefix=$dnsName --location=$location --user=$linuxAdmin"
echo ""
echo "To test the connection"
echo "    kubectl get nodes"
echo ""
echo "Next steps"
echo "    https://github.com/Azure/acs-engine/blob/master/docs/kubernetes.md"
echo ""
echo "################################################################################################################"