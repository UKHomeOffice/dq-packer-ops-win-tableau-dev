Start-Transcript -path C:\PerfLogs\userdata_output.log -append

# First work out if host has joined a Domain or is still part of Workgroup
Write-Host "Checking if host joined to a domain, yet"
$is_part_of_domain = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
$workgroup = (Get-WmiObject -Class Win32_ComputerSystem).Workgroup
$is_part_of_workgroup = $workgroup -eq "WORKGROUP"
$is_part_of = ""
$is_part_of_valid = $false

if ($is_part_of_domain -eq $true -and $is_part_of_workgroup -eq $false)
{
    $is_part_of = "DOMAIN"
    $my_domain = Get-ADDomain
    $my_domain_name = $my_domain.Name
    $my_domain_name_full = $my_domain.Forest
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
    if ($my_domain_name_full)
    {
        Write-Host "Domain = $my_domain_name_full"
    }
}
else
{
    Write-Host "DEBUG! is_part_of_domain = $is_part_of_domain, is_part_of_workgroup = $is_part_of_workgroup"
}


# Get the IP Address and break it down into managable parts
Write-Host 'Getting IP address of host!'
$my_ip_full = Get-Netipaddress -addressfamily ipv4
$my_ip = $my_ip_full[0].ipaddress
Write-Host "IP address of host = $my_ip"

$octets = $my_ip -split "\."
$subnet_part = $octets[0] + "." + $octets[1]
$host_part = $octets[2] + "." + $octets[3]


# Try to figure out the Environment from the IP address
Write-Host "Deciphering the Environment from subnet part of the IP Address $subnet_part"
if($subnet_part -eq "10.8")
{
    $environment = "NotProd"
}
elseif($subnet_part -eq "10.2")
{
    $environment = "Prod"
}
elseif ($octets[0] -eq "172")
{
    # When Packer is building the Instance (or copying the AMI) the IP address starts 172.
    # No point in trying to do anything clever in this userdata script yet
    $environment = "Building..."
}
else
{
    $environment = "UNKNOWN"
}
$environment_lc = $environment.ToLower()
Write-Host ">>>>>>>>>>> Environment is $environment! <<<<<<<<<<<<<"


# Get current hostname
$current_hostname = $env:computername
Write-Host "The current hostname is $current_hostname"


# Stop if not a valid environment
if ($environment -eq "NotProd" -or $environment -eq "Prod")
{
    Write-Host "The environment is  $environment, continuing to configure computer..."
}
else
{
    Write-Host "As the environment is $environment, not trying set up any more. Exiting..."
    Exit 0
}


# Decipher desired host name
Write-Host "Deciphering the desired name of the host from the host part of the IP Address $host_part !"
if (-not $host_part)
{
    $new_hostname = "UNKNOWN"
}
elseif ($host_part -eq "6.10")
{
    $new_hostname = "TAB-DEP-1"
}
elseif ($host_part -eq "6.11")
{
    $new_hostname = "TAB-DEP-2"
}
elseif ($host_part -eq "6.12")
{
    $new_hostname = "TAB-DEP-3"
}
elseif ($host_part -eq "6.15")
{
    $new_hostname = "TAB-DEP-2019"
}
else
{
    $new_hostname = "TAB-DEP-$octets[3]"
}
Write-Host ">>>>>>>>>>> Host should be named $new_hostname <<<<<<<<<<<<<"


# Env vars
Write-Host 'Environment Variables'
$env_flag_file = "\PerfLogs\env.txt"
$env_flag = (Test-Path $env_flag_file)
if (-not $env_flag)
{
    Write-Host 'Setting config bucket environment variable'
    [Environment]::SetEnvironmentVariable("S3_OPS_CONFIG_BUCKET", "s3-dq-ops-config-$environment_lc/sqlworkbench", "Machine")
    [System.Environment]::SetEnvironmentVariable("S3_OPS_CONFIG_BUCKET", "s3-dq-ops-config-$environment_lc/sqlworkbench")
    New-Item -Path $env_flag_file -ItemType "file" -Value "Environment variables set. Remove this file to re-run." | Out-Null
}
else
{
    Write-Host 'Environment variables already set'
}


# Rename Computer
# If the host has not already been renamed
if ($current_hostname -ne $new_hostname)
{
    Write-Host "Renaming host from $current_hostname to $new_hostname - and RESTARTING"
    Rename-Computer -NewName $new_hostname -Force -Restart
    Sleep 600 # To prevent script from continuing before restart takes effect
}
else
{
    Write-Host "Hostname already correct ($current_hostname = $new_hostname)"
}



#  Join to Domain
# If the host has not already joined the domain
if ($is_part_of_domain -eq $false -and $is_part_of_valid -eq $true)
{
    Write-Host 'Join Computer to the DQ domain'
    Write-Host "Retrieving joiner username and password"
    $joiner_usr = (Get-SSMParameter -Name "AD_Domain_Joiner_Username" -WithDecryption $False).Value
    if (!$?)
    {
        Write-Host "Cannot retrieve Domain Joiner Username. Exiting..."
        Exit 1
    }
    $joiner_pwd = (Get-SSMParameter -Name "AD_Domain_Joiner_Password" -WithDecryption $True).Value
    if (!$?)
    {
        Write-Host "Cannot retrieve Domain Joiner Password. Exiting..."
        Exit 1
    }
    Write-Host "Successfully retrieved joiner username ($joiner_usr) and password"
    $domain = 'dq.homeoffice.gov.uk'
    $username = $joiner_usr + "@" + $domain
    $password = ConvertTo-SecureString $joiner_pwd -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($username,$password)

    Write-Host "Joining host to Domain $domain using user $username - without rename option - and RESTARTING"
    Add-Computer -DomainName $domain -Credential $credential -Restart -Force
    Sleep 600 # To prevent script from continuing before restart takes effect
}
else
{
    Write-Host "Host already joined to domain"
}


# These settings seem a little flaky.
# Check each value each time until all 4 settings are set - then set the flag file to skip this for subsequent runs
Write-Host 'Region and Locale'
$reg_flag_file = "\PerfLogs\reg.txt"
$reg_flag = (Test-Path $reg_flag_file)
if (-not $reg_flag)
{
    Write-Host "Home Location"
    $reg_home_loc = $False
    $home_location = Get-WinHomeLocation
    if ($home_location.GeoId -eq "242")
    {
        Write-Host "Home Location already set to United Kingdom"
        $reg_home_loc = $True # only set to true when confirmed correct via Get (not after Set)
    }
    else
    {
        Write-Host 'Setting home location to the United Kingdom'
        Set-WinHomeLocation 242
    }


    Write-Host 'System Locale'
    $reg_sys_loc = $False
    $sys_loc = Get-WinSystemLocale
    if ($sys_loc.Name -eq "en-GB")
    {
        Write-Host "System Locale already set to British"
        $reg_sys_loc = $True # only set to true when confirmed correct via Get (not after Set)
    }
    else
    {
        Write-Host "Setting System Locale to British"
        Set-WinSystemLocale en-GB
    }


    Write-Host "Region"
    $reg_reg_cult = $False
    $reg_cult = Get-Culture
    if ($reg_cult.Name -eq "en-GB")
    {
        Write-Host "Regional format already set to British"
        $reg_reg_cult = $True # only set to true when confirmed correct via Get (not after Set)
    }
    else
    {
        Write-Host 'Setting regional format (date/time etc.) to English (United Kingdon) - only applies to current user'
        Set-Culture en-GB
    }


    Write-Host "TimeZone"
    $reg_time_zone = $False
    $time_zone = Get-TimeZone
    if ($time_zone.Id -eq "GMT Standard Time")
    {
        Write-Host "TimeZone already set to GMT"
        $reg_time_zone = $True # only set to true when confirmed correct via Get (not after Set)
    }
    else
    {
        Write-Host 'Setting TimeZone to GMT'
        Set-TimeZone "GMT Standard Time"
    }


    if ($reg_home_loc -and $reg_sys_loc -and $reg_reg_cult -and $reg_time_zone)
    {
        New-Item -Path $reg_flag_file -ItemType "file" -Value "Region and Locale set. Remove this file to re-add." | Out-Null
    }
    else
    {
        Write-Host "Region and Locale not confirmed as set yet"
    }
}
else
{
    Write-Host 'Region and Locale already set'
}



Stop-Transcript
