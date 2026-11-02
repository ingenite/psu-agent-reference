#Requires -Version 7.4

param(
    [ValidateSet('All', 'Data', 'Reports', 'Dashboards', 'Factories', 'Tools')]
    [string[]] $Suite = @('All')
)

# Synopsis: Run all Pester tests, or a union of the selected development suites.
Add-BuildTask Test {
    & (Join-Path $BuildRoot 'tools/Invoke-RepositoryTest.ps1') -Suite $Suite
}

# Synopsis: Check PowerShell source with the repository's PSScriptAnalyzer settings.
Add-BuildTask Analyze {
    & (Join-Path $BuildRoot 'tools/Invoke-RepositoryAnalysis.ps1')
}

Add-BuildTask . Test
