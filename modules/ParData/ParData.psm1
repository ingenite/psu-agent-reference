param(
    [ValidateNotNull()]
    [hashtable] $FixturePaths = @{}
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:SourceFixturePaths = @{
    IntuneDevice = (Join-Path $PSScriptRoot '../../data/intune-devices.csv')
}

$sharedFixtureVariable = Get-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
$sharedFixturePaths = @{}
if ($null -ne $sharedFixtureVariable) {
    if ($sharedFixtureVariable.Value -isnot [hashtable]) {
        throw 'PAR_FixturePaths must be a hashtable of source names and fixture paths.'
    }
    $sharedFixturePaths = $sharedFixtureVariable.Value
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

. (Join-Path $PSScriptRoot 'Public/Get-ParIntuneDevice.ps1')

Export-ModuleMember -Function Get-ParIntuneDevice
