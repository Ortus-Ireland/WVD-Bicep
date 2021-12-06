param
(
    [Parameter(Mandatory = $true)]
    [string] $domainname,
    [string] $netbiosname,
    [string] $adminPassword,
    [string] $OUpath,
    [string] $clientName,
    [string] $officelocation,
    [string] $UPNsuffix
)

# Config regional settings
Set-Culture en-IE
Set-WinHomeLocation 68
Set-WinSystemLocale en-IE
Set-WinUserLanguageList en-IE -Force

# Set Timezone
tzutil /s "GMT Standard Time"

# Set custom regional parameters for each new user

mkdir C:\Ortus

$MaxSize = (Get-PartitionSupportedSize -DriveLetter c).sizeMax

Resize-Partition -DriveLetter c -Size $MaxSize

#==================================
# Configure second disk for DC1
#==================================
Get-Disk | Where-Object partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -DriveLetter F -UseMaximumSize | Format-Volume -FileSystem NTFS -AllocationUnitSize 65536  -Confirm:$false


# Enable remote management
Configure-SMRemoting.exe -enable
Enable-PSRemoting -Force
Set-item wsman:localhost\client\trustedhosts -value * -Force

#==================================
# Configure page file
#==================================
$computer = Get-WmiObject Win32_computersystem -EnableAllPrivileges
$computer.AutomaticManagedPagefile = $false
$computer.Put()
$CurrentPageFile = Get-WmiObject -Query "select * from Win32_PageFileSetting where name='c:\\pagefile.sys'"
$CurrentPageFile.delete()
Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{name="d:\pagefile.sys";InitialSize = 3072; MaximumSize = 3072}

##==================================
# Download Part 2 and create scheduled Task
#==================================
$taskName = "ConfigDC1part2"
$argument = "-NoProfile -noninteractive -executionpolicy bypass " + "-File C:\Ortus\DC1part2.ps1 " + $OUpath + " " + $clientName + " " + $officelocation + " " + $UPNsuffix

wget https://ortusmediastorage.blob.core.windows.net/public/ConfigDC1part2.ps1 -OutFile C:\Ortus\DC1part2.ps1

$taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -WorkingDirectory c:\Ortus\ -Argument $argument 
$taskTrigger = New-ScheduledTaskTrigger -AtStartup 
$taskTrigger.delay = 'PT1M'

$user = "NT AUTHORITY\SYSTEM"

Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -User $user -RunLevel Highest -Force
    
#==================================
# #Install Active Directoy
#==================================
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools
mkdir F:\Windows\NTDS
mkdir F:\Windows\SYSVOL
Import-Module ADDSDeployment
Install-addsforest -DomainName $domainname -DomainNetBIOSName $netbiosname -DatabasePath "F:\Windows\NTDS" -LogPath "F:\Windows\NTDS" -SYSVOLPath "F:\Windows\SYSVOL" -DomainMode "WinThreshold" -ForestMode "WinThreshold" -InstallDNS:$true -NoRebootOnCompletion:$false -Force:$true -safemodeadministratorpassword (convertto-securestring $adminPassword -asplaintext -force)
shutdown -r -t 30
