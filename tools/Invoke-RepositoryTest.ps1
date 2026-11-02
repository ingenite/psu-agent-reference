#Requires -Version 7.4

<#
.SYNOPSIS
Runs all repository Pester tests or selected development suites.
.DESCRIPTION
Uses the pinned Pester version from BuildDependencies.psd1. Dependencies must
already be installed; this command does not install modules or contact PSU.
All discovers every test file, excluding generated files under tools/output.
Named suites select tests by location, and combined suites deduplicate files.
Failures, discovery errors, and selections without runnable tests terminate.
.PARAMETER Suite
All (default), Data, Reports, Dashboards, Factories, or Tools. Supply multiple
named suites to run their union. All must be used alone. Tools selects only
tests directly in tools; Factories selects tools/factories recursively.
.INPUTS
None
.OUTPUTS
None

Pester writes console results and an NUnit3 XML report under tools/output/tests.
The report filename identifies the sorted suite selection and is overwritten
on the next run of that selection. Existing reports are not removed.
.EXAMPLE
./tools/Invoke-RepositoryTest.ps1 -Suite Dashboards,Data,Reports
Runs the dashboard, source-data, and report tests together.
.NOTES
Invoke-Build's Test task is the shared contributor and CI entry point. These
tests use synthetic data and mocks; success does not verify live PSU or Graph.
#>
[CmdletBinding()]
param(
    [ValidateSet('All', 'Data', 'Reports', 'Dashboards', 'Factories', 'Tools')]
    [string[]] $Suite = @('All')
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$dependencies = Import-PowerShellDataFile -LiteralPath (Join-Path $PSScriptRoot 'BuildDependencies.psd1')
Import-Module Pester -RequiredVersion $dependencies.Pester -ErrorAction Stop

$selectedSuites = @($Suite | Sort-Object -Unique)
if ($selectedSuites.Count -eq 0 -or ('All' -in $selectedSuites -and $selectedSuites.Count -gt 1)) {
    throw 'Select All alone, or one or more named test suites.'
}

$suiteDirectories = @{
    All = $repositoryRoot
    Data = Join-Path $repositoryRoot 'modules/ParData'
    Reports = Join-Path $repositoryRoot 'modules/ParReports'
    Dashboards = Join-Path $repositoryRoot 'dashboards'
    Factories = Join-Path $PSScriptRoot 'factories'
    Tools = $PSScriptRoot
}
$outputDirectory = Join-Path $PSScriptRoot 'output/tests'
$generatedPathPattern = Join-Path $PSScriptRoot 'output/*'
$testFiles = @(
    foreach ($suiteName in $selectedSuites) {
        $files = @(
            Get-ChildItem -LiteralPath $suiteDirectories[$suiteName] -Filter '*.Tests.ps1' -File -Recurse:($suiteName -ne 'Tools') |
                Where-Object { $_.FullName -notlike $generatedPathPattern }
        )
        if ($files.Count -eq 0) {
            throw "No Pester test files found for suite '$suiteName'."
        }
        $files.FullName
    }
) | Sort-Object -Unique

New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
$reportName = ($selectedSuites -join '-').ToLowerInvariant() + '.xml'
$reportPath = Join-Path $outputDirectory $reportName
$configuration = New-PesterConfiguration
$configuration.Run.Path = @($testFiles)
$configuration.Run.PassThru = $true
$configuration.Run.Exit = $false
$configuration.Run.Throw = $false
$configuration.TestResult.Enabled = $true
$configuration.TestResult.OutputFormat = 'NUnit3'
$configuration.TestResult.OutputPath = $reportPath
$configuration.Output.Verbosity = 'Detailed'
$result = Invoke-Pester -Configuration $configuration

Write-Host "Pester report: $reportPath"
if ($result.Result -ne 'Passed' -or $result.TotalCount -eq 0) {
    throw "Pester suite '$($selectedSuites -join ', ')' did not pass (result: $($result.Result), tests: $($result.TotalCount), failed: $($result.FailedCount))."
}
