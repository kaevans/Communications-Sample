# Communications Sample

This example shows how to use a custom verified domain with Azure Communication Service. It shows how to register a new authenticated SMTP sender and how to add a custom MailFrom in the email domain. It is intended as a starting point for developers looking to implement email using custom verified domains with Azure Communications Service. 

## Features

- Creates a new service principal that will be used for a new authenticated sender. 
- Assigns the new service principal the "Communication and Email Service Owner" role required for authenticated senders.
- Creates a new authenticated SMTP user. 
- Adds a new MailFrom to the the custom verified email domain.

## Getting Started

1. Clone the repository:
    ```bash
    git clone https://github.com/your-username/Communications-Sample.git
    ```
2. Navigate to the project directory:
    ```bash
    cd Communications-Sample
    ```
3. Configure pre-requisites
4. Change the 8 variables in the `test.ps1` script to match your Azure environment and run `test.ps1` to send a test email using your new authenticated sender with a custom MailFrom address. 



## Requirements

- PowerShell 7 or higher
- Latest version of the Azure CLI
- Latest version of the Communication module for the Azure CLI
- Permission to create service principals in your Entra tenant
- An existing Communication Service with an existing Email Communication Service
- An existing verified domain for the Communication Service
- Owner permission for the Communication Service, required to assign roles to the service principal
- Contributor permission on the resource group to add new resources

## Pre-requisites
1. Prior to execution, install the Microsoft.Graph module locally and connect to Azure CLI ensuring the Microsoft Graph endpoint is used.
Note that this step requires PowerShell 7 or higher. 

```PowerShell
# Install the Microsoft Graph PowerShell SDK if not already installed, and install or upgrade the Azure Communication module for the CLI
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force
}

az extension add --upgrade -n communication
```

This process may take some time to complete. Once completed, import the Microsoft.Graph module.

```PowerShell
# Import the Microsoft Graph PowerShell SDK module. May take some time to complete. 
Import-Module Microsoft.Graph
```

This step may also take some time to complete. Once completed, connect the Azure account using the Microsoft Graph endpoint.
```PowerShell
# Connect to Azure account and ensure the Microsoft Graph endpoint is used
Connect-AzAccount -UseDeviceAuthentication -AuthScope MicrosoftGraphEndpointResourceId
```

Finally you need to connect to the Microsoft Graph with the required permissions requests.
```PowerShell
# Connect to Microsoft Graph Command Line Tools with the required permissions
Connect-MgGraph -Scopes 'Application.ReadWrite.All'
```

## Usage
Now that the pre-requisites are complete, proceed with running the script.

1. Change the 8 variables in the `test.ps1` script to match your Azure environment and run `test.ps1` to send a test email using your new authenticated sender with a custom MailFrom address. 

| Syntax | Description |
| ----------- | ----------- |
| subscriptionId | The ID of your Azure subscription |
| tenantId | The ID of your Azure tenant |
| resourceGroupName  | The name of your Azure resource group |
| communicationServiceName  | The resource name of your Azure Communication Service |
| emailCommunicationServiceName | The resource name of your Azure Email Communication Service |
| emailDomainName  | The verified custom domain |
| senderUsername  | The username of your new authenticated user, such as 'user1' |
| destinationEmailAddress   | The email address of the recipient to send a test email to |
| keyVaultName | The name of the Azure KeyVault used to securely store the app secret

Execute the test script:

```powershell
# Login to Azure
az login 
# Set the subscription  context
az account set --subscription $subscriptionId
az extension add --upgrade -n communication

./test.ps1
```

The result is the user is added as an authenticated sender for the Communication Service.
![Image showing SMTP usernames for a Communication Service](/images/SMTPUsernames.png "SMTP Usernames")

The user is also added as a MailFrom to the custom verified domain. 
![MailFrom addresses added to a custom verified Email Communication Service domain](/images/MailFrom.png "MailFrom")

## Authorization
This version of the script creates a service principal and assigns it the role `Communication and Email Service Owner`. If you instead want to use a custom role, edit the `smtpSenderRoleDefinition.json` file with your subscription ID, resource group name, and Communication Service name and save the file. Then run the `customRoleDefintion.ps1` script to create a custom role definition. Update the `onboard.ps1` script to use the name of your new custom role definition `Communication Service SMTP Sender`. 

## Monitoring
Using this approach, you can migrate from individual mailboxes to authenticated senders to track utilization. You can use Azure Log Analytics to query the `ACSEmailStatusUpdateOperational` table to query mails sent per user per day. 

```kql
ACSEmailStatusUpdateOperational
| where DeliveryStatus == "Delivered"
| summarize DailyMailsSent = count() by SenderUsername, format_datetime(bin(TimeGenerated, 1d),'yyyy-MM-dd')
```

![Results from a Log Analytics query showing mails delivered per user per day as a table](/images/loganalytics.png "LogAnalyticsTable")

This information can then be used for alerts, dashboards, and workbooks.

![Results from a Log Analytics query showing mails delivered per user per day as a bar chart](/images/barchart.png "LogAnalyticsBarChart")

## Contributing

Contributions are welcome! Please open issues or submit pull requests for improvements.

## License

This project is licensed under the [MIT License](LICENSE).

## Contact

For questions or support, please open an issue in this repository.