param(
    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,
    [Parameter(Mandatory=$true)]
    [string]$tenantId,
    [Parameter(Mandatory=$true)]
    [string]$resourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$communicationServiceName,
    [Parameter(Mandatory=$true)]
    [string]$emailCommunicationServiceName,
    [Parameter(Mandatory=$true)]
    [string]$emailDomainName,
    [Parameter(Mandatory=$true)]
    [string]$senderUsername
)

# This script creates a service principal and assigns it the Communication and Email Service Owner role for the specified communication service.
# It also creates an SMTP user for the email domain and a sender MailFrom for the email domain.

$senderEmailAddress = $senderUsername + "@" + $emailDomainName

# Login to Azure
az login 
# Set the subscription  context
az account set --subscription $subscriptionId
az extension add --upgrade -n communication


# Create application service principal  and assign role and get the password    
$spAppId = az ad sp create-for-rbac --name $senderEmailAddress --role "Communication and Email Service Owner" --scopes /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Communication/communicationServices/$communicationServiceName --query "appId" --output tsv 
$spPassword = az ad sp credential reset --id $spAppId --query "password" --output tsv

# Create the email communication service SMTP user used to authenticate to the email domain
az communication smtp-username create --comm-service-name $communicationServiceName --name $senderUsername --resource-group $resourceGroupName --entra-application-id $spAppId --username $senderEmailAddress --tenant-id $tenantId

# Create a sender MailFrom for the email domain 
az communication email domain sender-username create --domain-name $emailDomainName --email-service-name $emailCommunicationServiceName --name $senderUsername --resource-group $resourceGroupName --display-name $senderEmailAddress --username $senderUsername

#WARNING: The following writes sensitive information to the console.
# This includes the service principal password and the sender email address.
$spInfo = @{
    appId = $spAppId
    password = $spPassword
    senderEmailAddress = $senderEmailAddress
}   
Write-Output $spInfo