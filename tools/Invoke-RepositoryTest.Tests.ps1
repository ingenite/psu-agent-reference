Describe 'Repository test task' {
    BeforeAll {
        $runnerPath = Join-Path $PSScriptRoot 'Invoke-RepositoryTest.ps1'
        $dependenciesPath = Join-Path $PSScriptRoot 'BuildDependencies.psd1'
        $buildPath = Join-Path $PSScriptRoot '../psu-agent-reference.build.ps1'
        $pwshPath = (Get-Process -Id $PID).Path

        function Invoke-TestBuild {
            param([string] $Suite = 'All')

            $output = & $pwshPath -NoProfile -File (Join-Path $testRepository 'Invoke-TestTask.ps1') -Suite $Suite 2>&1 | Out-String
            [pscustomobject]@{
                ExitCode = $LASTEXITCODE
                Output = $output
            }
        }
    }

    BeforeEach {
        $testRepository = Join-Path $TestDrive 'repository'
        $directories = @('modules/ParData', 'modules/ParReports', 'dashboards/Example', 'tools/factories', 'tools/output/probes', 'endpoints')
        foreach ($directory in $directories) {
            New-Item -Path (Join-Path $testRepository $directory) -ItemType Directory -Force | Out-Null
        }
        Copy-Item -LiteralPath $runnerPath -Destination (Join-Path $testRepository 'tools')
        Copy-Item -LiteralPath $dependenciesPath -Destination (Join-Path $testRepository 'tools')
        Copy-Item -LiteralPath $buildPath -Destination $testRepository

        $passingTest = "Describe 'Synthetic task check' { It 'passes' { 1 | Should -Be 1 } }"
        foreach ($directory in @('modules/ParData', 'modules/ParReports', 'dashboards/Example', 'tools/factories', 'tools', 'endpoints')) {
            Set-Content -LiteralPath (Join-Path $testRepository "$directory/Example.Tests.ps1") -Value $passingTest
        }
        Set-Content -LiteralPath (Join-Path $testRepository 'tools/output/probes/Ignored.Tests.ps1') -Value "throw 'Generated output must not be discovered.'"
        Set-Content -LiteralPath (Join-Path $testRepository 'Invoke-TestTask.ps1') -Value @'
param([string] $Suite)
$ErrorActionPreference = 'Stop'
$dependencies = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'tools/BuildDependencies.psd1')
Import-Module InvokeBuild -RequiredVersion $dependencies.InvokeBuild
Invoke-Build -File (Join-Path $PSScriptRoot 'psu-agent-reference.build.ps1') -Suite ($Suite -split ',')
'@
    }

    It 'runs the complete default suite, discovers new locations, and excludes generated output' {
        $result = Invoke-TestBuild
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $report = [xml](Get-Content -LiteralPath (Join-Path $testRepository 'tools/output/tests/all.xml') -Raw)
        $report.'test-run'.total | Should -Be 6
        $report.'test-run'.result | Should -Be 'Passed'
    }

    It 'combines selected suites without duplicate test files' {
        $result = Invoke-TestBuild -Suite 'Reports,Data,Data'
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $report = [xml](Get-Content -LiteralPath (Join-Path $testRepository 'tools/output/tests/data-reports.xml') -Raw)
        $report.'test-run'.total | Should -Be 2
    }

    It 'keeps direct tools tests separate from factory tests' {
        $result = Invoke-TestBuild -Suite 'Tools'
        $result.ExitCode | Should -Be 0 -Because $result.Output
        $report = [xml](Get-Content -LiteralPath (Join-Path $testRepository 'tools/output/tests/tools.xml') -Raw)
        $report.'test-run'.total | Should -Be 1
    }

    It 'fails the build on a failing assertion and still writes a failure report' {
        Set-Content -LiteralPath (Join-Path $testRepository 'modules/ParData/Example.Tests.ps1') -Value "Describe 'Synthetic failure' { It 'fails' { 1 | Should -Be 2 } }"
        $result = Invoke-TestBuild -Suite 'Data'
        $result.ExitCode | Should -Not -Be 0
        $report = [xml](Get-Content -LiteralPath (Join-Path $testRepository 'tools/output/tests/data.xml') -Raw)
        $report.'test-run'.failed | Should -Be 1
        $report.'test-run'.result | Should -Be 'Failed'
    }

    It 'fails the build when test discovery throws' {
        Set-Content -LiteralPath (Join-Path $testRepository 'modules/ParData/Example.Tests.ps1') -Value "throw 'Synthetic discovery failure.'"
        $result = Invoke-TestBuild -Suite 'Data'
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'Synthetic discovery failure'
    }

    It 'fails the build when selected files contain no runnable tests' {
        Set-Content -LiteralPath (Join-Path $testRepository 'modules/ParData/Example.Tests.ps1') -Value '# Intentionally contains no tests.'
        $result = Invoke-TestBuild -Suite 'Data'
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'tests: 0'
    }

    It 'fails the build when a selected suite has no test files' {
        Remove-Item -LiteralPath (Join-Path $testRepository 'modules/ParData/Example.Tests.ps1')
        $result = Invoke-TestBuild -Suite 'Data'
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match "No Pester test files found for suite 'Data'"
    }

    It 'rejects mixing All with a focused suite' {
        $result = Invoke-TestBuild -Suite 'All,Data'
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'Select All alone'
    }
}
