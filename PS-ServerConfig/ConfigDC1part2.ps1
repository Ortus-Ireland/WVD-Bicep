#======================================================================================
# Define Variables

param
(
    [Parameter(Mandatory = $true)]
    [string] $OUpath,
    [string] $clientName,
    [string] $officelocation,
    [string] $UPNsuffix
)




#$domainname = "ad.metac.ie"                  # AD domain name 
#$OUpath = "DC=ad,DC=metac,DC=ie"           # Path to Active Directory root
#$companyname =  "METAC"                   # Name for company OU
#$officelocation = "Mountrath"                      # Name of location OU
#$UPNsuffix = "metac.ie"

#======================================================================================

# Remove DNS forwarder
Get-DnsServerForwarder | Remove-DnsServerForwarder -Force
Add-DnsServerForwarder -IPAddress 8.8.8.8 -PassThru
Add-DnsServerForwarder -IPAddress 8.8.4.4 -PassThru

# Enable Active Directory Recycle bin
import-module activedirectory
$tmp = "CN=Recycle Bin Feature,CN=Optional Features,CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration," + $OUpath
Enable-ADOptionalFeature �Identity $tmp �Scope ForestOrConfigurationSet �Target $addomain

# Add underscrore to company name
$_clientName = "_" + $clientName

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
$comppath = "OU=Computers,OU=" + $officelocation + ",OU=" + $_clientName + "," + $OUpath
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