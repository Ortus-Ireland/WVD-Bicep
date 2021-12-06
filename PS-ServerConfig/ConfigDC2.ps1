# Define Variables
param
(
    [Parameter(Mandatory = $true)]
    [string] $domainname,
    [string] $adminPassword,
    [string] $OUpath,
    [string] $clientName,
    [string] $officelocation,
    [string] $UPNsuffix
)

$adminUser = $domainname + "\localadmin"
$adminPassword = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential ($adminUser, $adminPassword)

# Config regional settings
Set-Culture en-IE 
Set-WinHomeLocation 68 
Set-WinSystemLocale en-IE
Set-WinUserLanguageList en-IE -Force

# Set Timezone
tzutil /s "GMT Standard Time"

# Set custom regional parameters for each new user

mkdir C:\Ortus
#download zip file containing reg file and default ntuser.dat
#wget http://start.ortus.ie/files/Ortus.zip -OutFile C:\Ortus\Ortus.zip

#extract zip file
#$shell = new-object -com shell.application
#$zip = $shell.NameSpace(�C:\Ortus\Ortus.zip�)
#foreach($item in $zip.items())
#{
#$shell.Namespace(�C:\�).copyhere($item)
#}

#add reg data to registry and copy ntuser.dat
#regedit /s C:\Ortus\defaultuser\default.reg
#Copy-item c:\Ortus\defaultuser\ntuser.dat C:\Users\Default\NTUSER.DAT


$MaxSize = (Get-PartitionSupportedSize -DriveLetter c).sizeMax

Resize-Partition -DriveLetter c -Size $MaxSize


#==================================
# Configure second disk for DC2
#==================================
Get-Disk | Where-Object partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -DriveLetter F -UseMaximumSize | Format-Volume -FileSystem NTFS -AllocationUnitSize 65536  -Confirm:$false

# Enable remote management
Configure-SMRemoting.exe -enable

#==================================
# Configure page file
#==================================
$computer = Get-WmiObject Win32_computersystem -EnableAllPrivileges
$computer.AutomaticManagedPagefile = $false
$computer.Put()
$CurrentPageFile = Get-WmiObject -Query "select * from Win32_PageFileSetting where name='c:\\pagefile.sys'"
$CurrentPageFile.delete()
Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{name="d:\pagefile.sys";InitialSize = 3072; MaximumSize = 3072}

#==================================
# Configure DC1 OU
#==================================
$DC1 = "DC1." + $domainname | Out-File -FilePath c:\Ortus\log.txt -Append
wget https://ortusmediastorage.blob.core.windows.net/public/ConfigDC1part2.ps1 -OutFile C:\Ortus\DC1part2.ps1

Enable-PSRemoting -Force
Set-item wsman:localhost\client\trustedhosts -value * -Force

Invoke-Command -ComputerName $DC1 -Credential $Credentials -FilePath C:\Ortus\DC1part2.ps1 -ArgumentList $OUpath,$clientName,$officelocation,$UPNsuffix


Start-Sleep -s 10
#=========================================
# #Install Active Directoy and Promote DC
#=========================================
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools
mkdir F:\Windows\NTDS
mkdir F:\Windows\SYSVOL
Import-Module ADDSDeployment

Start-Sleep -s 10

Install-ADDSDomainController -InstallDNS:$true -Credential $Credentials -DomainName $domainname -DatabasePath "F:\Windows\NTDS" -LogPath "F:\Windows\NTDS" -SYSVOLPath "F:\Windows\SYSVOL" -Force:$true -safemodeadministratorpassword (convertto-securestring $adminPassword -asplaintext -force)

shutdown -r -t 30

#Reboot Required
