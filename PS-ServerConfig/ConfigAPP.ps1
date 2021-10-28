#=========================================================================
# Define Variables
      
param
(
    [Parameter(Mandatory = $true)]
    [string] $domainname,
    [string] $OUpath,
    [string] $clientName,
    [string] $adminPassword
)

$adminUser = $domainname + "\localadmin"
$securePassword = $adminPassword | ConvertTo-SecureString -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential ($adminUser, $securePassword)

#=========================================================================

# Add underscrore to company name
$_clientName = "_" + $clientName

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
# Configure storage spaces for App
#==================================
Get-Disk | Where-Object partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -DriveLetter F -UseMaximumSize | Format-Volume -FileSystem NTFS -AllocationUnitSize 65536  -Confirm:$false


# Configure page file
#==================================
$computer = Get-WmiObject Win32_computersystem -EnableAllPrivileges
$computer.AutomaticManagedPagefile = $false
$computer.Put()
$CurrentPageFile = Get-WmiObject -Query "select * from Win32_PageFileSetting where name='c:\\pagefile.sys'"
$CurrentPageFile.delete()
Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{name="d:\pagefile.sys";InitialSize = 3072; MaximumSize = 3072}



#Enable Shadows with max space of 16GB (/maxsize=16256MB)
vssadmin add shadowstorage /for=F: /on=C:/maxsize=16256MB

#Create Shadows
vssadmin create shadow /for=F:

#Set Shadow Copy Scheduled Task for F: AM
$Action=new-scheduledtaskaction -execute "c:\windows\system32\vssadmin.exe" -Argument "create shadow /for=F:"
$Trigger=new-scheduledtasktrigger -daily -at 7:00AM
Register-ScheduledTask -TaskName ShadowCopyC_AM -Trigger $Trigger -Action $Action -Description "ShadowCopyF_AM"
#Set Shadow Copy Scheduled Task for F: 12PM
$Action=new-scheduledtaskaction -execute "c:\windows\system32\vssadmin.exe" -Argument "create shadow /for=F:"
$Trigger=new-scheduledtasktrigger -daily -at 12:00PM
Register-ScheduledTask -TaskName ShadowCopyC_PM -Trigger $Trigger -Action $Action -Description "ShadowCopyF_12PM"
#Set Shadow Copy Scheduled Task for F: 3PM
$Action=new-scheduledtaskaction -execute "c:\windows\system32\vssadmin.exe" -Argument "create shadow /for=F:"
$Trigger=new-scheduledtasktrigger -daily -at 3:00PM
Register-ScheduledTask -TaskName ShadowCopyC_PM -Trigger $Trigger -Action $Action -Description "ShadowCopyF_3PM"


#Install .NET 3.5
Install-WindowsFeature Net-Framework-Core

#install Print Server role
Install-WindowsFeature Print-Services

#Install Data Deduplication
Install-WindowsFeature -Name FS-Data-Deduplication

#Enable Data Deduplication on F Drive
Enable-DedupVolume -Volume F: -UsageType Default

#Domain join server
$comppath = "OU=Servers,OU=Azure,OU=" + $_clientName + "," + $OUpath
Add-Computer -DomainName $domainname -OUPath $comppath -Credential $Credentials

shutdown -r -t 30