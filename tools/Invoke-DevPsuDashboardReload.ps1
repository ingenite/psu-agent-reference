#Requires -Version 7.0

<#
.SYNOPSIS
Reloads dashboard configuration in the local dev-psu instance.
.DESCRIPTION
Uses the dev-psu-codex-mgmt-api secret from the current user's registered vault.
Calls the dashboards.ps1 configuration reload verified with PSU 2026.3.0.
.EXAMPLE
./tools/Invoke-DevPsuDashboardReload.ps1
#>

$appToken = Get-Secret -Name 'dev-psu-codex-mgmt-api' -AsPlainText -ErrorAction Stop
$headers = @{ Authorization = "Bearer $appToken" }

Invoke-RestMethod -Uri 'http://127.0.0.1:5100/api/v1/configuration/sync/dashboards.ps1' `
    -Method Put -Headers $headers -MaximumRedirection 0 -ErrorAction Stop | Out-Null

Write-Host 'Reloaded dev-psu dashboard configuration.'
