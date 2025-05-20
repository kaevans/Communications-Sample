<#

.SYNOPSIS
    This script creates a custom role definition for the Azure Communication Service SMTP Sender role. 
.DESCRIPTION
    This script creates a custom role definition for the Azure Communication Service SMTP Sender role. To use this, update the smtpSenderRoleDefinition.json file with the appropriate values for your environment.

.PARAMETER roleDefinitionFilePath
    The path to the JSON file that contains the role definition. The default value is "smtpSenderRoleDefinition.json".

.EXAMPLE    
    .\customRoleDefinition.ps1 

    This example creates a custom role definition using the provided JSON file.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$roleDefinitionFilePath = "smtpSenderRoleDefinition.json"
)

az role definition create --role-definition smtpSenderRoleDefinition.json
