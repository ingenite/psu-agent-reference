#Requires -Version 7.4

<#
.SYNOPSIS
Checks repository PowerShell files with the selected PSScriptAnalyzer rules.
.DESCRIPTION
Uses the pinned PSScriptAnalyzer version from BuildDependencies.psd1 and the
root PSScriptAnalyzerSettings.psd1. Dependencies must already be installed.
Checks .ps1, .psm1, and .psd1 files, including hidden PSU configuration and tests.
Excludes Git internals and generated files under tools/output. Does not execute
the analyzed scripts, apply fixes, install modules, or contact PSU.
Terminates on analyzer errors, any unsuppressed diagnostic, or no source files.
.INPUTS
None
.OUTPUTS
None

Writes console findings and tools/output/analysis/findings.json. The JSON report
is an array, including an empty array on success, and is replaced on each run.
.EXAMPLE
./tools/Invoke-RepositoryAnalysis.ps1
Checks repository PowerShell source with the configured built-in rules.
.NOTES
Invoke-Build's Analyze task is the shared contributor and CI entry point.
PSMisleadingBacktick detects whitespace after a backtick, not all continuation.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$dependencies = Import-PowerShellDataFile -LiteralPath (Join-Path $PSScriptRoot 'BuildDependencies.psd1')
Import-Module PSScriptAnalyzer -RequiredVersion $dependencies.PSScriptAnalyzer -ErrorAction Stop
$settings = Import-PowerShellDataFile -LiteralPath (Join-Path $repositoryRoot 'PSScriptAnalyzerSettings.psd1')
$generatedPathPattern = Join-Path $PSScriptRoot 'output/*'
$gitPathPattern = Join-Path $repositoryRoot '.git/*'
$sourceFiles = @(
    Get-ChildItem -LiteralPath $repositoryRoot -File -Recurse -Force |
        Where-Object {
            $_.Extension -in '.ps1', '.psm1', '.psd1' -and
            $_.FullName -notlike $generatedPathPattern -and
            $_.FullName -notlike $gitPathPattern
        } | Sort-Object FullName
)
if ($sourceFiles.Count -eq 0) {
    throw 'No PowerShell source files found for analysis.'
}

$findings = @(
    foreach ($sourceFile in $sourceFiles) {
        Invoke-ScriptAnalyzer -Path $sourceFile.FullName -Settings $settings -ErrorAction Stop |
            Select-Object ScriptPath, Line, Column, RuleName, @{ Name = 'Severity'; Expression = { [string] $_.Severity } }, Message
    }
)
$outputDirectory = Join-Path $PSScriptRoot 'output/analysis'
New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
$reportPath = Join-Path $outputDirectory 'findings.json'
ConvertTo-Json -InputObject $findings -Depth 4 | Set-Content -LiteralPath $reportPath
Write-Host "PSScriptAnalyzer report: $reportPath"

if ($findings.Count -gt 0) {
    $findings | Format-Table ScriptPath, Line, RuleName, Severity, Message -Wrap | Out-Host
    throw "PSScriptAnalyzer found $($findings.Count) diagnostic(s) in $($sourceFiles.Count) PowerShell files."
}
Write-Host "PSScriptAnalyzer passed: $($sourceFiles.Count) PowerShell files, no diagnostics."
