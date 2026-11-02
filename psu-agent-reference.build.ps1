#Requires -Version 7.4

param(
    [ValidateSet('All', 'Data', 'Reports', 'Dashboards', 'Factories', 'Tools')]
    [string[]] $Suite = @('All')
)

# Synopsis: Run all Pester tests, or a union of the selected development suites.
task Test {
    & (Join-Path $BuildRoot 'tools/Invoke-RepositoryTest.ps1') -Suite $Suite
}

task . Test
