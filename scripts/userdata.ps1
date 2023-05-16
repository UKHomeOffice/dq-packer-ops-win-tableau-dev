Start-Transcript -path C:\PerfLogs\userdata_output.log -append

Write-Host "Checking if host joined to a domain, yet"
$is_part_of_domain = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
$workgroup = (Get-WmiObject -Class Win32_ComputerSystem).Workgroup
$is_part_of_workgroup = $workgroup -eq "WORKGROUP"
$is_part_of = ""
$is_part_of_valid = $false

if ($is_part_of_domain -eq $true -and $is_part_of_workgroup -eq $false)
{
    $is_part_of = "DOMAIN"
    $is_part_of_valid = $true
}
elseif ($is_part_of_workgroup -eq $true -and $is_part_of_domain -eq $false)
{
    $is_part_of = "WORKGROUP"
    $is_part_of_valid=$true
}
elseif ($is_part_of_domain -eq $true -and $is_part_of_workgroup -eq $true)
{
    $is_part_of = "BOTH"
    Write-Host "ERROR! The host appears to be part of a DOMAIN AND a WORKGROUP!"
}
elseif (-not $is_part_of_domain -eq $true -and -not $is_part_of_workgroup -eq $true)
{
    $is_part_of = "NEITHER"
    Write-Host "ERROR! The host appears to be neither part of a DOMAIN NOR part of a WORKGROUP!"
}
else
{
    $is_part_of = "ERROR"
    Write-Host "ERROR! Cannot work out if host is part of a DOMAIN or part of a WORKGROUP!"
}

if ($is_part_of_valid)
{
    Write-Host "Host is part of $is_part_of"
}
else
{
    Write-Host "DEBUG! is_part_of_domain = $is_part_of_domain, is_part_of_workgroup = $is_part_of_workgroup"
}

Write-Host 'Getting IP address of host!'
$my_ip_full = Get-Netipaddress -addressfamily ipv4
$my_ip = $my_ip_full[0].ipaddress
Write-Host "IP address of host = $my_ip"

$octets = $my_ip -split "\."
$subnet = $octets[0] + "." + $octets[1]


Write-Host "Deciphering the Environment from subnet $subnet"
if($subnet -eq "10.8")
{
$environment = "NotProd"

}

elseif($subnet -eq "10.2")
{
$environment = "Prod"

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

Write-Host 'Adding bucket variable'
[Environment]::SetEnvironmentVariable("S3_OPS_CONFIG_BUCKET", "s3-dq-ops-config-$environment/sqlworkbench", "Machine")
[System.Environment]::SetEnvironmentVariable('S3_OPS_CONFIG_BUCKET','s3-dq-ops-config-$environment/sqlworkbench')

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
