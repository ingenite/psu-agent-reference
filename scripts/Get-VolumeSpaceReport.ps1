#Requires -Version 7.4

<#
.SYNOPSIS
Returns the synthetic volume-space report as JSON in PowerShell or a PSU job.
.DESCRIPTION
Imports the adjacent repository module explicitly and serializes its report.
No disks are read or changed. PSU saves the JSON string in Pipeline Output.
.PARAMETER MinimumFreePercent
Optional threshold override, from 0 through 100. Omit it to use the module default.
.INPUTS
None
.OUTPUTS
String containing a JSON array with Name, FreePercent, and Status for each row.
Use ConvertFrom-Json for objects, or call Get-ParVolumeReport directly.
.EXAMPLE
./scripts/Get-VolumeSpaceReport.ps1 -MinimumFreePercent 30
Returns Low, Low, and OK for the demonstration volumes.
#>
[CmdletBinding()]
param([int] $MinimumFreePercent)

Import-Module (Join-Path $PSScriptRoot '../modules/ParVolumeReport/ParVolumeReport.psd1')
# PSU 2026.3.0 dev jobs lost PSCustomObject properties in saved pipeline output.
ConvertTo-Json -InputObject @(Get-ParVolumeReport @PSBoundParameters)
