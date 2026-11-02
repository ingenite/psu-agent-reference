Describe 'Repository analysis task' {
    BeforeAll {
        $pwshPath = (Get-Process -Id $PID).Path

        function Invoke-AnalyzerBuild {
            $output = & $pwshPath -NoProfile -File (Join-Path $testRepository 'Invoke-AnalysisTask.ps1') 2>&1 | Out-String
            [pscustomobject]@{
                ExitCode = $LASTEXITCODE
                Output = $output
            }
        }
    }

    BeforeEach {
        $testRepository = Join-Path $TestDrive "repository-$(New-Guid)"
        foreach ($directory in 'tools/output/probes', '.universal', '.git', 'modules', 'scripts') {
            New-Item -Path (Join-Path $testRepository $directory) -ItemType Directory -Force | Out-Null
        }
        foreach ($file in 'Invoke-RepositoryAnalysis.ps1', 'BuildDependencies.psd1') {
            Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination (Join-Path $testRepository 'tools')
        }
        foreach ($file in 'PSScriptAnalyzerSettings.psd1', 'psu-agent-reference.build.ps1') {
            Copy-Item -LiteralPath (Join-Path $PSScriptRoot "../$file") -Destination $testRepository
        }
        Set-Content -LiteralPath (Join-Path $testRepository 'Invoke-AnalysisTask.ps1') -Value @'
$ErrorActionPreference = 'Stop'
$dependencies = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'tools/BuildDependencies.psd1')
Import-Module InvokeBuild -RequiredVersion $dependencies.InvokeBuild
& (Join-Path (Get-Module InvokeBuild).ModuleBase 'Invoke-Build.ps1') Analyze -File (Join-Path $PSScriptRoot 'psu-agent-reference.build.ps1')
'@
        $reportPath = Join-Path $testRepository 'tools/output/analysis/findings.json'
    }

    It 'passes clean source, allows valid backtick continuation, and excludes generated output and Git internals' {
        $validContinuation = 'Write-Output `' + "`n    'example'"
        Set-Content -LiteralPath (Join-Path $testRepository 'scripts/Example.ps1') -Value $validContinuation
        foreach ($path in 'tools/output/probes/Ignored.ps1', '.git/Ignored.ps1') {
            Set-Content -LiteralPath (Join-Path $testRepository $path) -Value 'function Broken- {'
        }

        $result = Invoke-AnalyzerBuild
        $result.ExitCode | Should -Be 0 -Because $result.Output
        (Get-Content -LiteralPath $reportPath -Raw).Trim() | Should -Be '[]'
    }

    It 'fails on <Name> and retains diagnostic details' -ForEach @(
        @{ Name = 'a warning'; Source = 'gci'; Rule = 'PSAvoidUsingCmdletAliases'; Severity = 'Warning' }
        @{ Name = 'an error'; Source = "ConvertTo-SecureString 'synthetic' -AsPlainText -Force"; Rule = 'PSAvoidUsingConvertToSecureStringWithPlainText'; Severity = 'Error' }
        @{ Name = 'a misleading backtick'; Source = 'Write-Output ` ' + "`n'example'"; Rule = 'PSMisleadingBacktick'; Severity = 'Warning' }
    ) {
        Set-Content -LiteralPath (Join-Path $testRepository 'scripts/Example.ps1') -Value $Source

        $result = Invoke-AnalyzerBuild
        $result.ExitCode | Should -Not -Be 0
        $findings = @(Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json)
        $finding = $findings | Where-Object RuleName -EQ $Rule
        $finding | Should -Not -BeNullOrEmpty
        $finding.Severity | Should -Be $Severity
        $finding.Line | Should -Be 1
        $finding.ScriptPath | Should -Be (Join-Path $testRepository 'scripts/Example.ps1')
    }

    It 'fails on parse errors in <Path>' -ForEach @(
        @{ Path = '.universal/settings.ps1' }
        @{ Path = 'modules/Example.psm1' }
        @{ Path = 'modules/Example.psd1' }
        @{ Path = 'scripts/Example.Tests.ps1' }
    ) {
        Set-Content -LiteralPath (Join-Path $testRepository $Path) -Value '@{ Broken = '

        $result = Invoke-AnalyzerBuild
        $result.ExitCode | Should -Not -Be 0
        $findings = @(Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json)
        $findings.Severity | Should -Contain 'ParseError'
        $findings.ScriptPath | Should -Contain (Join-Path $testRepository $Path)
    }
}
