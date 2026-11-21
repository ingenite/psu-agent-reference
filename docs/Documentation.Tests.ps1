#Requires -Version 7.4

# ADR-0010 limits: raising a limit here should be a deliberate, reviewed decision.
Describe 'Documentation limits' {
    BeforeAll {
        $maximumErrataLines = 40
        $allowedEntries = @('adr', 'directory-guide.md', 'Documentation.Tests.ps1', 'errata.md', 'README.md')
        $errataLines = @(Get-Content -LiteralPath "$PSScriptRoot/errata.md")
        $entries = @(Get-ChildItem -LiteralPath $PSScriptRoot -Force | Select-Object -ExpandProperty Name)
    }

    It 'keeps errata within its line budget' {
        $errataLines.Count | Should -BeLessOrEqual $maximumErrataLines
    }

    It 'keeps errata as one table row per gap' {
        $proseLines = @($errataLines | Select-Object -Skip 1 | Where-Object { $_ -and $_ -notlike '|*' })
        $proseLines.Count | Should -BeLessOrEqual 5
    }

    It 'keeps docs limited to the index, directory guide, errata, and ADRs' {
        $unexpectedEntries = @($entries | Where-Object { $_ -notin $allowedEntries })
        $unexpectedEntries | Should -BeNullOrEmpty
    }
}
