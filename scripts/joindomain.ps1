Start-Transcript -path C:\PerfLogs\userdata_output.log -append

Write-Host 'Getting IP address of host!'
$myip = Get-Netipaddress -addressfamily ipv4

$firstoctate = $myip[0].ipaddress.Substring(0,4)
$secondoctate = $myip[0].ipaddress.Substring(5,4)

Write-Host $firstoctate
Write-Host $secondoctate

Write-Host 'Deciphering the Environment!'
if($firstoctate -eq "10.8")
{
$environment = "notprod"

}

elseif($firstoctate -eq "10.2")
{
$environment = "prod"

}

else {
$environment = "test"

}

Write-Host ">>>>>>>>>>> Environment is $environment! <<<<<<<<<<<<<"

Write-Host 'Deciphering the Bastion!'
if($secondoctate -eq "6.10")
{
$bastion = "DEVELOPMENT"

}

elseif($secondoctate -eq "6.11")
{
$bastion = "DEPLOYMENT"

}

else {
$bastion = "TABLEAU-DEV+"

}

Write-Host ">>>>>>>>>>> Host is $bastion <<<<<<<<<<<<<"


Write-Host 'Join System to the DQ domain'
$joiner_pw = (Get-SSMParameter -Name "AD_AdminPasswordd" -WithDecryption $True).Value
$domain = 'dq.homeoffice.gov.uk'
$username = 'dq\domain_joiner'
$password = ConvertTo-SecureString $joiner_pw -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username,$password)

Rename-Computer -NewName $bastion
sleep 20
Add-Computer -DomainName $domain -Options JoinWithNewName,AccountCreate -Credential $credential -restart -force

Stop-Transcript
