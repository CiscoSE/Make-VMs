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
Used for demonstrating clone performance for HyperFlex.

.PARAMETER NumberOfVMs
Use this parameter to configure how many copies of the template VM you want to make.
Depending on your system, this could generate a lot of storage usage, and it is best
to have a isolated Datastore for running this test. Ensure that the datastore is 
physically capable of holding the entire capacity that will be generated. 

Note that some systems will post process deduplication, so you should not assume
deduplication will ensure all VMs fit into your defined storage. 

.PARAMETER User
Enter the user name for your vCenter. By default we set this to administrator@vsphere.local

.PARAMETER Password
You must enter the password for the user name provided above.

.PARAMETER Server
This needs to be the fully qualified DNS name for the vCenter supporting the HX cluster

.PARAMETER Cluster
The Name of the cluster in vCenter for the machines to be created in.

.PARAMETER Template
The name of the template that will be copied. This is the basis for all of the machines to be created.

.PARAMETER Datastore
The Datastore used for the VMS. 


.EXAMPLE
Create 100 systems

.\make-machines.ps1 -NumberOfVMs 100 -User useraccount@yourdomain.local -Password 'YourPassword' -Template YourTemplateName -Server yourvcenter.yourdomain.local -Cluster YourClusterName -Datastore YourDatastoreName -Verbose

#>
[cmdletbinding()]
Param(

[parameter(position=0,mandatory=$false)][int]$NumberOfVMs = 250,
[Parameter(position=1,mandatory=$false)][string]$User = "administrator@vsphere.local",
[Parameter(position=4,mandatory=$true) ][string]$Server,
[Parameter(position=5,mandatory=$true) ][string]$Template,  
[Parameter(position=6,mandatory=$true) ][string]$Cluster,     
[Parameter(position=7,mandatory=$true) ][string]$Datastore

)

$credentials = Get-Credential -UserName $user -message "Enter Password for $User"

write-verbose "Import Modules for PowerCLI. We assume you have them installed."
write-verbose "You can pull these from the PowerShell Gallery if needed."
import-module PowerCLI.ViCore -erroraction silentlycontinue
import-module VMware.VimAutomation.Core -ErrorAction SilentlyContinue

Write-Verbose "Checking to see if we have disabled invalidCertificate checking in PowerCLI"
Set-PowerCLIConfiguration -scope Session -InvalidCertificateAction ignore -Confirm:$false

write-verbose "Check for existing connection to vCenter and kill it if we find it."
if (-not [string]::IsNullOrEmpty($global:DefaultVIServer)){
    write-verbose $global:DefaultVIServer
    Write-Verbose "Found an existing connection. Disconnecting it."
    Disconnect-VIServer -Confirm:$False
}

Write-Verbose "Connect to vCenter using credentials provided."
connect-VIServer $Server -user $User -Credential $credentials -force

$ScriptBlock = {
    param(
        [string]$Password,
	    [string]$User,
        [string]$Server,
        [string]$Template,
        [string]$vmName,
        [string]$Cluster,
        [string]$Datastore
    )
    write-host "Configuring $($vmName)"
    get-cluster $Cluster | new-vm -Name $vmName -Template $Template -Datastore $Datastore -runasync
}
measure-command {
    1..$NumberOfVMs | %{
        invoke-command -scriptblock $ScriptBlock -args $Password,$User,$Server,$Template,"TestVM-$($_)",$Cluster,$Datastore
    }
    do {
        sleep 1
        Write-Verbose "Expected $($NumberofFMs). Only Seeing $(get-vm TestVM-*)"
        }until(
        (get-vm TestVM-*).count -eq $NumberOfVMs)

    get-vm TestVM-* | %{
        Write-Host "Starting VM $($_.Name)"
        start-vm $_ -RunAsync
        }
}
disconnect-VIServer -confirm:$false

