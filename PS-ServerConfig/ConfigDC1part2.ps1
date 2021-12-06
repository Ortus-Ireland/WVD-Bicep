param
(
    [Parameter(Mandatory = $true)]
    [string] $OUpath = $args[0],
    [string] $clientName = $args[1],
    [string] $officelocation = $args[2],
    [string] $UPNsuffix = $args[3]
)

#======================================================================================

# Remove DNS forwarder
Add-DnsServerForwarder -IPAddress 8.8.4.4 -PassThru

# Enable Active Directory Recycle bin
import-module activedirectory

# Add underscrore to company name
$_clientName = "_" + $clientName | Out-File -FilePath c:\Ortus\log.txt -Append

Import-Module ActiveDirectory 
# Create OU in ACtive Directory
New-ADOrganizationalUnit -Name $_clientName -Path $OUpath
$OUpathtmp = "OU=" + $_clientName + "," + $OUpath
New-ADOrganizationalUnit -Name Azure -Path $OUpathtmp
New-ADOrganizationalUnit -Name $officelocation -Path $OUpathtmp
$OUpathtmp2 = "OU=" + "Azure," + $OUpathtmp
New-ADOrganizationalUnit -Name Servers -Path $OUpathtmp2
New-ADOrganizationalUnit -Name Users -Path $OUpathtmp2
$OUpathtmp3 = "OU=" + $officelocation + "," + $OUpathtmp
New-ADOrganizationalUnit -Name Computers -Path $OUpathtmp3
New-ADOrganizationalUnit -Name Users -Path $OUpathtmp3

#Set default OU for new computers
$comppath = "OU=Computers,OU=" + $officelocation + ",OU=" + $_clientName + "," + $OUpath | Out-File -FilePath c:\Ortus\log.txt -Append
redircmp $comppath

#import group policy for windows updates and link
#import-module grouppolicy
#Import-GPO -BackupGPOName "Windows Updates - Download but do not install" -CreateIfNeeded -Path "C:\Ortus\GPO\Windows Update" -TargetName "Windows Updates - Download but do not install"
#$gppath = "OU=Servers,OU=Azure,OU=" + $_companyname + "," + $OUpath
#new-gplink -name "Windows Updates - Download but do not install" -target $gppath 
#$gppath = "OU=Domain Controllers," + $OUpath
#new-gplink -name "Windows Updates - Download but do not install" -target $gppath

#Install Windows Server backup
#Add-WindowsFeature Windows-Server-Backup

#Enable DNS Scavenging
Set-DnsServerScavenging -ScavengingState $TRUE -ScavengingInterval 7.00:00:00 -ApplyOnAllZones -Verbose -PassThru

#Add UPN suffix
$currentForest = Get-ADForest
Set-ADForest -Identity $currentForest -UPNSuffixes @{Add=$UPNsuffix}