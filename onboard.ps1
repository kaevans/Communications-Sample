<#

.SYNOPSIS
    This script creates a service principal and assigns it the Communication and Email Service Owner role for the specified communication service.
    It also creates an SMTP user for the email domain and a sender MailFrom for the email domain.
.DESCRIPTION
    This script creates a service principal and assigns it the Communication and Email Service Owner role for the specified communication service.
    It also creates an SMTP user for the email domain and a sender MailFrom for the email domain.
.PARAMETER subscriptionId
    The subscription ID of the Azure subscription.
.PARAMETER tenantId
    The tenant ID of the Azure Active Directory.                
.PARAMETER resourceGroupName
    The name of the resource group where the communication service is located.
.PARAMETER communicationServiceName
    The name of the communication service.
.PARAMETER emailCommunicationServiceName
    The name of the email communication service.
.PARAMETER emailDomainName
    The name of the email domain.
.PARAMETER senderUsername
    The username of the sender.
.EXAMPLE    
    .\onboard.ps1 -subscriptionId "<YOUR SUBSCRIPTION ID>" -tenantId "<YOUR TENANT ID>" -resourceGroupName "<YOUR RESOURCE GROUP NAME>" -communicationServiceName "<YOUR COMMUNICATION SERVICE NAME>" -emailCommunicationServiceName "<YOUR EMAIL SERVICE NAME>" -emailDomainName "<YOUR EMAIL DOMAIN>" -senderUsername "<SENDER USERNAME WITHOUT THE DOMAIN, such as 'user1'>"

    This example creates a service principal and assigns it the Communication and Email Service Owner role for the specified communication service.
    It also creates an SMTP user for the email domain and a sender MailFrom for the email domain.
    It returns the service principal appId, password, and sender email address.
#>
[CmdletBinding()]
[OutputType([hashtable])]


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
