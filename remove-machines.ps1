<#

.NOTES
Copyright (c) 2018 Cisco and/or its affiliates.
This software is licensed to you under the terms of the Cisco Sample
Code License, Version 1.0 (the "License"). You may obtain a copy of the
License at
               https://developer.cisco.com/docs/licenses
All use of the material herein must be in accordance with the terms of
the License. All rights not expressly granted by the License are
reserved. Unless required by applicable law or agreed to separately in
writing, software distributed under the License is distributed on an "AS
IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
or implied.

.DESCRIPTION
Used to bulk delete machines from vmware. This script is highly dangerous if you don't know what
your doing. Make sure you know what it does before you use.

.PARAMETER User
Enter the user name for your vCenter. By default we set this to administrator@vsphere.local

.PARAMETER Password
You must enter the password for the user name provided above.

.PARAMETER Server
This needs to be the fully qualified DNS name for the vCenter supporting the HX cluster

.PARAMETER Cluster
The Name of the cluster in vCenter for the machines to be deleted from.

.EXAMPLE
Delete all systems start with Test-VM

.\Remove-machines.ps1 -User useraccount@yourdomain.local -Password 'YourPassword' -Server yourvcenter.yourdomain.local -Cluster YourClusterName -Verbose

#>
[cmdletbinding()]
Param(
[Parameter(position=1,mandatory=$false)][string]$User = "administrator@vsphere.local",
[Parameter(position=3,mandatory=$true) ][string]$Password,
[Parameter(position=4,mandatory=$true) ][string]$Server,   
[Parameter(position=6,mandatory=$true) ][string]$Cluster,
[Parameter(position=7,mandatory=$false) ][string]$VMsToKill = "TestVM*",
[Parameter(position=8,mandatory=$false)][switch]$IGetIt = $False
)

#This fail safe ensures that the stript does not run until you understand the risks. 
if ($IGetIt -eq $False){
    write-Host "This script will irrevocalbly delete systems."
    write-host "Used improperly, it could delete every system you have."
    write-host "This code will not run until you make certain changes."
    write-host "Read and understand the code before running it again." 
    exit
}
write-verbose "Import Modules for PowerCLI. We assume you have them installed."
write-verbose "You can pull these from the PowerShell Gallery if needed."
import-module PowerCLI.ViCore -erroraction silentlycontinue
import-module VMware.VimAutomation.Core -ErrorAction SilentlyContinue

Write-verbose "Starting VM Deletion"
Set-PowerCLIConfiguration -scope Session -InvalidCertificateAction Ignore -confirm:$false
write-verbose "Check for existing connection to vCenter and kill it if we find it."
if (-not [string]::IsNullOrEmpty($global:DefaultVIServer)){
    write-verbose $global:DefaultVIServer
    Write-Verbose "Found an existing connection. Disconnecting it."
    Disconnect-VIServer -Confirm:$False
}

Write-Verbose "Connect to vCenter using credentials provided."
connect-VIServer $Server -user $User -password $Password -force

#Get systems to remove from cluster.
get-cluster $cluster | get-vm -name "$VMsToKill" | %{
    write-verbose "$($_.name) is being removed"
    if ($_.powerstate -eq "PoweredOff"){
        remove-vm $_.name -confirm:$false -DeletePermanently -runAsync
        }
    else {
        stop-vm $_.name -confirm:$false | %{remove-vm $_.name -confirm:$false -DeletePermanently -runAsync}
        }
    }
disconnect-viserver -confirm:$false
