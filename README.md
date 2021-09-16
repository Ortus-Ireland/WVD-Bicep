Create Storage Account
Create VNET
    -Create VM Subnet
    -Create Gateway Subnet
    -Create Wireguard Subnet
    -Set Static DNS
Create Local Network Gateway using Client External IP
Create Virtual Network Gateway
Create Gateway Connection VPN using virtual network gateway and local network gateway
Create Network Security Group
    -Allow RDP from Ortus Cloud and Dublin
    -Allow DNS from Client External IP
Create Public IP for DC Load Balancer
Create Public IP for APP Load Balancer
Create DC Load Balancer
    -Allow RDP in using user defined custom ports
Create APP Load Balancer
    -Allow RDP in using user defined custom ports
Create Managed Availability Set
Create NICs for 2 DC Servers & APP server and add to Load Balancer and NSG
Create Servers
    -Use small disk image
    -Add 2 X DC's to Availability Set
    -Create 32GB data disks and attach for DC Servers
    -Create 127GB data disk and attach for APP Server
Create Diagnostic Storage for 3 X Servers
Crate necessary resources & Wireguard VM
Custom Script to configure  DC1
    -Set culture, home location, locale, language
    -Resize C Drive
    -Attach and format F drive
    -Configure Page file
    -Create scheduled task for configDC1part2 script at reboot
    -Install Active Directory and create domain
Custom Script to configure  DC2
    -Set culture, home location, locale, language
    -Resize C Drive
    -Attach and format F drive
    -Configure Page file
    -Install Active Directory and DCPromo
Custom Script to configure APP Server
    -Set culture, home location, locale, language
    -Resize C Drive
    -Attach and format F drive
    -Configure Page file
    -Install .Net 3.5
    -Install Data Dedup
    -Turn on Data Dedup on F:
    -Domain Join VM
Custom Script to configure Wireguard Server
    -Create conf files based on details provided
Create Recovery Services
    -Set Storage to locally redundant
    -Create Backup Policy - D180 / W12 / M60 / Y7
    -Add DC1 and APP server to Backup
Creat WVD Hostpool. Appgroup, Workspace
Create Route Table for Wireguard

