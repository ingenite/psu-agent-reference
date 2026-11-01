param(
    [ValidateNotNull()]
    [hashtable] $FixturePaths = @{}
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:SourceFixturePaths = @{
    IntuneDevice = (Join-Path $PSScriptRoot '../../data/intune-devices.csv')
    EntraUser = (Join-Path $PSScriptRoot '../../data/entra-users.csv')
    CmdbAsset = (Join-Path $PSScriptRoot '../../data/cmdb-assets.csv')
    PersonMapping = (Join-Path $PSScriptRoot '../../data/cmdb-person-mappings.csv')
}

$sharedFixtureVariable = Get-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
$sharedFixturePaths = @{}
if ($null -ne $sharedFixtureVariable) {
    $sharedFixturePaths = $sharedFixtureVariable.Value
    if ($sharedFixturePaths -is [string]) {
        try {
            $sharedFixturePaths = ConvertFrom-Json -InputObject $sharedFixturePaths -AsHashtable -NoEnumerate -ErrorAction Stop
        }
        catch {
            throw 'PAR_FixturePaths must be a hashtable or JSON object of source names and fixture paths.'
        }
    }
    if ($sharedFixturePaths -isnot [hashtable]) {
        throw 'PAR_FixturePaths must be a hashtable or JSON object of source names and fixture paths.'
    }
}

foreach ($configuredFixturePaths in @($sharedFixturePaths, $FixturePaths)) {
    foreach ($sourceName in $configuredFixturePaths.Keys) {
        if ($sourceName -notin $script:SourceFixturePaths.Keys) {
            throw "Unknown fixture source '$sourceName'."
        }
        if ($configuredFixturePaths[$sourceName] -isnot [string] -or $configuredFixturePaths[$sourceName].Trim() -eq '') {
            throw "Fixture path for '$sourceName' must be a nonblank string."
        }
        $script:SourceFixturePaths[$sourceName] = $configuredFixturePaths[$sourceName]
    }
}

# Anchor relative configuration at import so later working-directory changes do not retarget retrieval.
foreach ($sourceName in @($script:SourceFixturePaths.Keys)) {
    $path = $script:SourceFixturePaths[$sourceName]
    if (-not (Split-Path -Path $path -IsAbsolute)) {
        $script:SourceFixturePaths[$sourceName] = Join-Path (Get-Location).Path $path
    }
}

. (Join-Path $PSScriptRoot 'Private/Read-ParFixtureCsv.ps1')
. (Join-Path $PSScriptRoot 'Public/Get-ParIntuneDevice.ps1')
. (Join-Path $PSScriptRoot 'Public/Get-ParEntraUser.ps1')
. (Join-Path $PSScriptRoot 'Public/Get-ParCmdbAsset.ps1')
. (Join-Path $PSScriptRoot 'Public/Get-ParCmdbPersonMapping.ps1')

Export-ModuleMember -Function Get-ParIntuneDevice, Get-ParEntraUser, Get-ParCmdbAsset, Get-ParCmdbPersonMapping
