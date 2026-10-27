Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Public/ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport.ps1')
. (Join-Path $PSScriptRoot 'Public/Get-ParIntuneDeviceWithoutPrimaryUserReport.ps1')
. (Join-Path $PSScriptRoot 'Public/Resolve-ParIntuneDeviceCmdbAsset.ps1')
. (Join-Path $PSScriptRoot 'Public/Resolve-ParCmdbAssignedUser.ps1')
. (Join-Path $PSScriptRoot 'Public/Compare-ParDeviceAssignedUser.ps1')

Export-ModuleMember -Function Get-ParIntuneDeviceWithoutPrimaryUserReport, ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport, Resolve-ParIntuneDeviceCmdbAsset, Resolve-ParCmdbAssignedUser, Compare-ParDeviceAssignedUser
