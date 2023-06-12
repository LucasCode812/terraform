#!/bin/bash

<powershell>

# Add ICMP to Windows Firewall
New-NetFirewallRule -DisplayName "Allow ICMP" -Protocol ICMPv4 -IcmpType 8 -Action Allow

# Wazuh agent
$IP_ADDRESS = "10.0.2.10"
$PORT = "1514"

# Start install when Wazuh-Manager is on
function Check-Port {
    param (
        [string]$IpAddress,
        [int]$Port
    )
    
    try {
        $socket = New-Object System.Net.Sockets.TcpClient
        $socket.Connect($IpAddress, $Port)
        $socket.Close()
        return $true
    }
    catch {
        return $false
    }
}

while (-not (Check-Port -IpAddress $IP_ADDRESS -Port $PORT)) {
    Write-Host "Pinging $IP_ADDRESS on port $PORT..."
    Start-Sleep -Seconds 1
}

# Set download link
$InstallerUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.4.3-1.msi"
$InstallerPath = "$env:USERPROFILE\Desktop\wazuh-agent-4.4.3-1.msi"

# Download the installer
Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath

# Change working directory to desktop
Set-Location $env:USERPROFILE\Desktop

# Install agent
./wazuh-agent-4.4.3-1.msi /q WAZUH_MANAGER="10.0.2.10" WAZUH_AGENT_NAME="ADInstance"

# Start agent
NET START WazuhSvc

# Nagios Agent
# Set download link
$InstallerUrl = "https://assets.nagios.com/downloads/ncpa/ncpa-2.4.1.exe"
$InstallerPath = "$env:USERPROFILE\Desktop\ncpa-2.4.1.exe"

# Download the installer
Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath

# Change working directory to desktop
Set-Location $env:USERPROFILE\Desktop

# Connect NCPA agent to NagiosXI
./ncpa-2.4.1.exe /S /TOKEN='mytoken' /IP='10.0.2.11' /PORT='5693'

# Active Directory
# Create a new user account
$accountName = "ADAdmin"
$accountPassword = ConvertTo-SecureString -String "Student12345!" -AsPlainText -Force
New-LocalUser -Name $accountName -Password $accountPassword -AccountNeverExpires

# Add the user to the Administrators group
$adminGroup = "Administrators"
Add-LocalGroupMember -Group $adminGroup -Member $accountName

# Wait for creating to finalise 
Start-Sleep -Seconds 

# Import the Server Manager module
Import-Module ServerManager

# Install the Active Directory Domain Services feature
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote the server to a domain controller
$domainName = "AutomateAIO.com"
$domainNetbiosName = "AutomateAIO"
$adminPassword = ConvertTo-SecureString -String "Student12345!" -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("ADAdmin", $adminPassword)
Install-ADDSForest -DomainName $domainName -DomainNetbiosName $domainNetbiosName -InstallDns -NoRebootOnCompletion -Force:$true -SafeModeAdministratorPassword $adminPassword

# Restart the server to complete the promotion
Restart-Computer -Force

</powershell>