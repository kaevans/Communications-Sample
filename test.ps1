$subscriptionId = "<YOUR SUBSCRIPTION ID>"
$tenantId = "<YOUR TENANT ID>"
$resourceGroupName = "<YOUR RESOURCE GROUP NAME>"
$communicationServiceName = "<YOUR COMMUNICATION SERVICE NAME>"
$emailCommunicationServiceName = "<YOUR EMAIL SERVICE NAME>"
$emailDomainName = "<YOUR EMAIL DOMAIN>"
$senderUsername = "<SENDER USERNAME WITHOUT THE DOMAIN, such as 'user1'>"
$destinationEmailAddress = "<YOUR DESTINATION EMAIL ADDRESS>"
$keyVaultName = "<YOUR AZURE KEY VAULT NAME>"


# Requires PowerShell -Version 7.0 or higher
#Requires -Version 7


# Create a service principal, assign it the Communication and Email Service Owner role for the specified communication service,
# create an SMTP user for the email domain, and create a sender MailFrom for the email domain.
# It returns the service principal appId, password, and sender email address.
$output = @(.\onboard.ps1 -subscriptionId $subscriptionId -tenantId $tenantId -resourceGroupName $resourceGroupName -communicationServiceName $communicationServiceName -emailCommunicationServiceName $emailCommunicationServiceName -emailDomainName $emailDomainName -senderUsername $senderUsername)

# Save the password to an existing Azure Key Vault
az keyvault secret set --vault-name $keyVaultName --name $senderUsername --value $output.password

#Send a test email
$SmtpServer = "smtp.azurecomm.net"
$Port = 587

$Password = ConvertTo-SecureString -AsPlainText -Force -String $output.password
$Cred = New-Object -TypeName PSCredential -ArgumentList $output.senderEmailAddress, $Password

Write-Host "Sending test email to $destinationEmailAddress from $($output.senderEmailAddress)..." -ForegroundColor Green
Send-MailMessage -From $output.senderEmailAddress -To $destinationEmailAddress -Subject 'Hello from PowerShell' -Body 'test' -SmtpServer $SmtpServer -Port $Port -Credential $Cred -UseSsl
