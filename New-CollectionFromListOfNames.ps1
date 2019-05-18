<#
.SYNOPSIS
    Create a query based collection from an input file containing a list of computer names.
.DESCRIPTION
    Create a query based collection from an input file containing a list of computer names. Converts a list of computer names to a new query. Has options for
    limiting collection defaults to "All Systems" but can be customized. Input file defaults to a file named ComputerList.txt in the same directory the script 
    is ran from. Will probably turn this in to a GUI at some point.
.PARAMETER CollectionName
    The name you want to use for the new collection.
.PARAMETER LimitingCollectionID
    The CollectionID of the collection you would like to use as the limiting collection. This defaults to SMS00001 for All Systems.
.PARAMETER FilePath
    Default file path is $PSScriptRoot\ComputerList.txt and ComputerList.txt should only contain a list of computer names one per line. No commas or quotation marks should
    be included as that will be handled automatically by the script.
.PARAMETER FilePath
    SCCM Site code.
.EXAMPLE
    PS C:\> New-CollectionFromListOfNames -CollectionName "CLIENT - My List Sample Collection"
    Creates a collection named "CLIENT - My List Sample Collection" limited to All Systems with a query rule comprised of a list computer names from the ComputerList.txt file.
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    Author: Matt Atkinson/@ConfigMatt/Matt.Atkinson@gmail.com
    TO DO:
    1. Sanitize input file for invalid characters.
#>

param(
    [Parameter(Mandatory = $True)]
    [string]$CollectionName,
    [Parameter(Mandatory = $false)]
    $LimitingCollectionID = "SMS00001",
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    [parameter(Mandatory = $true)]
    [string]$SiteCode)


#Import ConfigMgr Module
Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
#initialize variables
$querylist = $null
if (!($FilePath)) {
    $filepath = Join-Path $PSScriptRoot ComputerList.txt
}

#Ensure the input file is present
if (Test-Path $FilePath) {
    Write-Output "Computer list exists"    
}
else {
    write-output "Computer list does not exist. Please make sure you have a ComputerList.txt file in the same directory you are running the script from."
}

#Read the input file.
$ComputerList = get-content $FilePath

#Convert the input file to a proper format with each computer name enclosed in single quotes with a comma and a new line after.
$computerlist = get-content $Filepath
foreach ($Computer in $ComputerList) {
    $comp = "`'$computer`',"
    $querylist = $querylist += ("$comp`n")
}
#remove last comma from list and build query for collection membership.
$querylist = $querylist.trim()
$querylist = $querylist.TrimEnd(",")
$CollectionQuery = "select SMS_R_System.ResourceId from  SMS_R_System where SMS_R_System.NetbiosName in ($QueryList)"

#Check to ensure query character count is less than 16383
if ($CollectionQuery.count -ge 16383) {
    Write-Output "List too long, max query length is 16383 characters. Your query length is $($collectionQuery.length)"
}

#switch to SCCM psdrive
set-location "$($sitecode):"
#Create the collection
New-CMDeviceCollection -LimitingCollectionId $LimitingCollectionID -Name $CollectionName -Comment "Built With Powershell Script 'New-CollectionFromListOfNames'"
#sleep 5 seconds to allow time for the collection to be created.
start-sleep -Seconds 5 

#Add the query rule to the collection
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $CollectionName -QueryExpression $CollectionQuery -RuleName CreatedByPowershell