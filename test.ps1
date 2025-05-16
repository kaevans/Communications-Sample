$subscriptionId = "<YOUR SABSCRIPTION ID>"
$tenantId = "<YOUR TENANT ID>"
$resourceGroupName = "<YOUR RESOURCE GROUP NAME>"
$communicationServiceName = "<YOUR COMMUNICATION SERVICE NAME>"
$emailCommunicationServiceName = "<YOUR EMAIL SERVICE NAME>"
$emailDomainName = "<YOUR EMAIL DOMAIN>"
$senderUsername = "<SENDER USERNAME WITHOUT THE DOMAIN, such as 'user1'>"
$destinationEmailAddress = "<YOUR DESTINATION EMAIL ADDRESS>"

$output = @(.\onboard.ps1 -subscriptionId $subscriptionId -tenantId $tenantId -resourceGroupName $resourceGroupName -communicationServiceName $communicationServiceName -emailCommunicationServiceName $emailCommunicationServiceName -emailDomainName $emailDomainName -senderUsername $senderUsername)


#Send a test email
$SmtpServer = "smtp.azurecomm.net"
$Port = 587

$Password = ConvertTo-SecureString -AsPlainText -Force -String $output.password
$Cred = New-Object -TypeName PSCredential -ArgumentList $output.senderEmailAddress, $Password

Send-MailMessage -From $senderEmailAddress -To $destinationEmailAddress -Subject 'Hello from PowerShell' -Body 'test' -SmtpServer $SmtpServer -Port $Port -Credential $Cred -UseSsl
