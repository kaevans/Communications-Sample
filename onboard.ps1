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

# Requires PowerShell -Version 7.0 or higher
#Requires -Version 7

param(
    # The subscription ID of the Azure subscription
    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,
    # The tenant ID of the Azure Active Directory 
    [Parameter(Mandatory=$true)]
    [string]$tenantId,
    # The name of the resource group where the communication service is located (e.g., "rg-email")
    [Parameter(Mandatory=$true)]
    [string]$resourceGroupName,
    # The name of the communication service (e.g., "cs-emaildemo-001")
    [Parameter(Mandatory=$true)]
    [string]$communicationServiceName,
    # The name of the email communication service (e.g., "ecs-emaildemo-001")
    [Parameter(Mandatory=$true)]
    [string]$emailCommunicationServiceName,
    # The name of the email domain (e.g., "kirke.work")
    [Parameter(Mandatory=$true)]
    [string]$emailDomainName,
    # The username of the sender, without the domain (e.g., "user1")
    [Parameter(Mandatory=$true)]
    [string]$senderUsername,
    # The duration in years for which the service principal password will be valid.
    [Parameter(Mandatory=$false)]
    [int]$passwordDurationYears = 2
)



# Finds the existing service principal and role assignment, and if one does not exist, creates a new 
# service principal and assigns it the Communication and Email Service Owner role for the specified communication service.
function Add-AppAndRoleAssignment {
    param (
        [string]$senderEmailAddress,
        [string]$tenantId,
        [string]$subscriptionId,
        [string]$resourceGroupName,
        [string]$communicationServiceName
    )
    

    # Use the Azure CLI to ensure that a service principal with the specified name does not already exist
    $spAppId = az ad sp list --display-name $senderEmailAddress --query "[?appOwnerOrganizationId=='$tenantId'].{appId:appId}" --output tsv

    if ($spAppId) {
        # Use the Azure CLI to ensure that the service principal has the "Communication and Email Service Owner" role for the specified communication service
        $existingRoleAssignment = az role assignment list --assignee $spAppId --role "Communication and Email Service Owner" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Communication/communicationServices/$communicationServiceName --query "[?principalType=='ServicePrincipal'].{appId:appId}" --output tsv
        if (-not ($existingRoleAssignment)) {
            # If the service principal exists but does not have the role, assign the role
            az role assignment create --assignee $spAppId --role "Communication and Email Service Owner" --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Communication/communicationServices/$communicationServiceName
        }
    }
    else {
        # Use the Azure CLI to add a role assignment "Communication and Email Service Owner" for the service principal
        $spAppId = az ad sp create-for-rbac --name $senderEmailAddress --role "Communication and Email Service Owner" --scopes /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Communication/communicationServices/$communicationServiceName --query "appId" --output tsv 
    }

    return $spAppId
}

# Adds a new password to the service principal with a specified duration in years.
function Add-AppPassword(
    [string]$spAppId,
    [int]$passwordDurationYears = 2
) {
    # Import the Microsoft Graph PowerShell SDK module

    $appObjectId = (Get-AzADApplication -ApplicationId $spAppId).Id

    $passwordCred = @{
        displayName = 'Created in PowerShell'
        endDateTime = (Get-Date).AddYears($passwordDurationYears)
    }

    $secret = Add-MgApplicationPassword -applicationId $appObjectId -PasswordCredential $passwordCred

    return $secret.SecretText
}

$senderEmailAddress = $senderUsername + "@" + $emailDomainName

# Add the service principal and assign it the Communication and Email Service Owner role for the specified communication service
$spAppId = Add-AppAndRoleAssignment -senderEmailAddress $senderEmailAddress -tenantId $tenantId -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName -communicationServiceName $communicationServiceName

# Add a new password to the service principal
$secret = Add-AppPassword -spAppId $spAppId

# Create the email communication service SMTP user used to authenticate to the email domain
az communication smtp-username create --comm-service-name $communicationServiceName --name $senderUsername --resource-group $resourceGroupName --entra-application-id $spAppId --username $senderEmailAddress --tenant-id $tenantId

# Create a sender MailFrom for the email domain 
az communication email domain sender-username create --domain-name $emailDomainName --email-service-name $emailCommunicationServiceName --name $senderUsername --resource-group $resourceGroupName --display-name $senderEmailAddress --username $senderUsername

#WARNING: The following writes sensitive information to the pipeline output.
# This includes the Entra application ID, the Entra application secret in plain text, and the sender email address.
$spInfo = @{
    appId = $spAppId
    password = $secret
    senderEmailAddress = $senderEmailAddress
}   
Write-Output $spInfo
