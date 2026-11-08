#Requires -Version 7.4

<#
.SYNOPSIS
Returns the synthetic volume-space report through a PSU GET endpoint.
.DESCRIPTION
PSU serializes the returned report objects as JSON. This endpoint reads no disks
and changes no state. PSU supplies the Repository variable for module loading.
.PARAMETER MinimumFreePercent
Optional integer query parameter, from 0 through 100. Omit it to use the module
default. Example: /api/par/v1/design/volume-space?MinimumFreePercent=30
.INPUTS
None
.OUTPUTS
PSCustomObject with Name, FreePercent, and Status, serialized by PSU as JSON.
.EXAMPLE
Invoke-RestMethod 'http://127.0.0.1:5100/api/par/v1/design/volume-space'
Returns the default demonstration report from the dedicated development instance.
#>
[CmdletBinding()]
param([int] $MinimumFreePercent)

Import-Module (Join-Path $Repository 'modules/ParVolumeReport/ParVolumeReport.psd1')
Get-ParVolumeReport @PSBoundParameters
