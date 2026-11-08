# Experimental only; not reference material for creating production PSU resources.
<#
.SYNOPSIS
Installs or restores benchmark-only registrations on the dedicated development instance.
.PARAMETER Restore
Restores the saved configuration files. Does not remove jobs, results, accounts, or database state.
.NOTES
Run only against C:\dev-psu. Uses its existing vaulted management token, never saved to disk.
#>
[CmdletBinding()]
param([switch] $Restore)
$ErrorActionPreference = 'Stop'
$repository = 'C:/dev-psu/Repository'
$backup = 'C:/dev-psu/bench-results/original-configuration'
$token = Get-Secret -Name dev-psu-codex-mgmt-api -AsPlainText
$headers = @{ Authorization = "Bearer $token" }
$files = 'scripts.ps1','endpoints.ps1','dashboards.ps1'
if ($Restore) {
    if (Test-Path "$backup/restored.txt") { throw 'Configuration was already restored; refusing to overwrite subsequent work.' }
    foreach ($file in $files) { Copy-Item "$backup/$file" "$repository/.universal/$file" -Force }
} else {
    if ((Test-Path $backup) -and !(Test-Path "$backup/restored.txt")) { throw 'Preview backup already exists; restore or inspect it before another installation.' }
    New-Item $backup -ItemType Directory -Force | Out-Null
    New-Item "$repository/tools/benchmarks" -ItemType Directory -Force | Out-Null
    New-Item "$repository/scripts/benchmarks" -ItemType Directory -Force | Out-Null
    foreach ($file in $files) { Copy-Item "$repository/.universal/$file" "$backup/$file" -Force }
    Remove-Item "$backup/restored.txt" -ErrorAction SilentlyContinue
    Copy-Item "$PSScriptRoot/Invoke-Workload.ps1","$PSScriptRoot/Get-CollectionWorkload.ps1","$PSScriptRoot/Invoke-BenchmarkJob.ps1","$PSScriptRoot/BenchmarkApp.ps1" "$repository/tools/benchmarks" -Force
    Copy-Item "$PSScriptRoot/Invoke-BenchmarkJob.ps1" "$repository/tools/benchmarks/Invoke-BenchmarkDiscard.ps1" -Force
    Copy-Item "$PSScriptRoot/Measure-Serialization.ps1" "$repository/tools/benchmarks" -Force
    Copy-Item "$PSScriptRoot/New-DirectoryFixture.ps1","$PSScriptRoot/Get-AdminWorkload.ps1","$PSScriptRoot/Invoke-AdminScenario.ps1" "$repository/tools/benchmarks" -Force
    Copy-Item "$PSScriptRoot/Invoke-Workload.ps1","$PSScriptRoot/Get-CollectionWorkload.ps1","$PSScriptRoot/Invoke-BenchmarkJob.ps1" "$repository/scripts/benchmarks" -Force
    Copy-Item "$PSScriptRoot/Invoke-BenchmarkJob.ps1" "$repository/scripts/benchmarks/Invoke-BenchmarkDiscard.ps1" -Force
    Add-Content "$repository/.universal/scripts.ps1" @'
New-PSUScript -Name 'Invoke-BenchmarkJob.ps1' -Path 'benchmarks/Invoke-BenchmarkJob.ps1' -Environment 'PowerShell 7' -MaxHistory 500
New-PSUScript -Name 'Invoke-BenchmarkDiscard.ps1' -Path 'benchmarks/Invoke-BenchmarkDiscard.ps1' -Environment 'PowerShell 7' -DiscardPipeline -MaxHistory 500
'@
    Add-Content "$repository/.universal/endpoints.ps1" @'
New-PSUEndpoint -Url '/api/par-benchmark' -Method POST -Environment 'PowerShell 7' -Endpoint {
    & 'C:/dev-psu/Repository/tools/benchmarks/Invoke-Workload.ps1' -RequestJson $Body
}
New-PSUEndpoint -Url '/api/par-benchmark-cache' -Method POST -Environment 'Integrated' -Authentication -Endpoint {
    & 'C:/dev-psu/Repository/tools/benchmarks/Invoke-Workload.ps1' -RequestJson $Body
}
New-PSUEndpoint -Url '/api/par-admin-benchmark' -Method POST -Environment 'Integrated' -Authentication -Endpoint {
    & 'C:/dev-psu/Repository/tools/benchmarks/Invoke-AdminScenario.ps1' -RequestJson $Body
}
New-PSUEndpoint -Url '/api/par-benchmark-cleanup' -Method POST -Environment 'Integrated' -Authentication -Endpoint {
    $keys = ($Body | ConvertFrom-Json).Keys
    foreach ($key in $keys) { if ($key -notlike 'par-bench:*') { throw 'Invalid benchmark key' }; Remove-PSUCache -Key $key -Integrated }
    @{ Removed = @($keys).Count }
}
'@
    Add-Content "$repository/.universal/dashboards.ps1" "New-PSUApp -Name 'PAR Benchmarks' -FilePath 'tools/benchmarks/BenchmarkApp.ps1' -BaseUrl '/par-benchmarks' -Environment 'PowerShell 7' -AutoDeploy"
    & "$PSScriptRoot/New-DashboardPlan.ps1"
}
foreach ($file in $files) {
    Invoke-RestMethod "http://127.0.0.1:5100/api/v1/configuration/sync/$file" -Method Put -Headers $headers -MaximumRedirection 0 | Out-Null
}
if ($Restore) {
    foreach ($file in $files) {
        if ((Get-FileHash "$backup/$file").Hash -ne (Get-FileHash "$repository/.universal/$file").Hash) { throw "Restore differs: $file" }
    }
    Set-Content "$backup/restored.txt" (Get-Date).ToUniversalTime().ToString('o')
}
Write-Output "Preview configuration updated. Original files: $backup"
