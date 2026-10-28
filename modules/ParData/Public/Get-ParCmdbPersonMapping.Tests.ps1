Describe 'CMDB person mapping retrieval' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '../ParData.psd1'
        $existingFixtureVariable = Get-Variable -Name PAR_FixturePaths -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeEach {
        Remove-Variable -Name PAR_FixturePaths -Scope Global -ErrorAction SilentlyContinue
        $fixturePath = Join-Path $TestDrive 'mapping[1].csv'
        $mapping = [pscustomobject][ordered]@{ personReference = ' person-001 '; userPrincipalName = ' Alex@example.invalid ' }
        $mapping | Export-Csv -LiteralPath $fixturePath -NoTypeInformation
        Remove-Module ParData -ErrorAction SilentlyContinue
        Import-Module $modulePath -ArgumentList @{ PersonMapping = $fixturePath } -Force
    }

    AfterAll {
        Remove-Module ParData -ErrorAction SilentlyContinue
        Remove-Variable -Name PAR_FixturePaths -Scope Global -ErrorAction SilentlyContinue
        if ($null -ne $existingFixtureVariable) {
            Set-Variable -Name PAR_FixturePaths -Scope Global -Value $existingFixtureVariable.Value
        }
    }

    Context 'Get-ParCmdbPersonMapping' {
        It 'preserves opaque values, whitespace, order, duplicates, UTF-8 and CSV escaping' {
            $second = [pscustomobject]@{ personReference = "person,`"É`"`n002"; userPrincipalName = 'other@example.invalid' }
            @($mapping, $second, $mapping) | Export-Csv -LiteralPath $fixturePath -NoTypeInformation -Encoding utf8
            $rows = @(Get-ParCmdbPersonMapping)
            $rows | Should -HaveCount 3
            $rows.personReference | Should -Be @($mapping.personReference, $second.personReference, $mapping.personReference)
            $rows[0].userPrincipalName | Should -BeExactly $mapping.userPrincipalName
            ($rows[0].PSObject.Properties.Name -join ',') | Should -BeExactly 'personReference,userPrincipalName'
        }

        It 'allows blank source keys and restores empty cells as null without interpreting them' {
            Set-Content -LiteralPath $fixturePath -Value @('personReference,userPrincipalName', ',', '   ,   ')
            $rows = @(Get-ParCmdbPersonMapping)
            $rows | Should -HaveCount 2
            ($null -eq $rows[0].personReference) | Should -BeTrue
            ($null -eq $rows[0].userPrincipalName) | Should -BeTrue
            $rows[1].personReference | Should -BeExactly '   '
            $rows[1].userPrincipalName | Should -BeExactly '   '
        }

        It 'returns no objects for <Name> files' -ForEach @(
            @{ Name = 'zero-byte'; Content = '' }
            @{ Name = 'whitespace-only'; Content = " `r`n " }
            @{ Name = 'header-only'; Content = 'personReference,userPrincipalName' }
        ) {
            Set-Content -LiteralPath $fixturePath -Value $Content -NoNewline
            @(Get-ParCmdbPersonMapping) | Should -HaveCount 0
        }

        It 'accepts reordered headers and LF or CRLF with or without a final newline' {
            foreach ($separator in @("`n", "`r`n")) {
                foreach ($ending in @('', $separator)) {
                    Set-Content -LiteralPath $fixturePath -Value ("userPrincipalName,personReference${separator}alex@example.invalid,person-001" + $ending) -NoNewline
                    (Get-ParCmdbPersonMapping).personReference | Should -BeExactly 'person-001'
                }
            }
        }

        It 'rejects malformed CSV or incompatible headers with no partial output: <Content>' -ForEach @(
            @{ Content = "personReference,userPrincipalName`nperson,alex`nbad" }
            @{ Content = "personReference,userPrincipalName`nperson,alex`n`"unbalanced,alex" }
            @{ Content = 'PersonReference,userPrincipalName' }
            @{ Content = 'personReference,personReference' }
            @{ Content = 'personReference' }
            @{ Content = 'personReference,userPrincipalName,extra' }
        ) {
            Set-Content -LiteralPath $fixturePath -Value $Content
            $received = @()
            $failure = $null
            try { Get-ParCmdbPersonMapping | ForEach-Object { $received += $_ } }
            catch { $failure = $_ }
            $failure.Exception.Message | Should -BeLike '*CMDB person mapping fixture*'
            $received | Should -HaveCount 0
        }

        It 'reports unreadable or missing inputs rather than returning empty success' {
            Remove-Item -LiteralPath $fixturePath
            { Get-ParCmdbPersonMapping } | Should -Throw '*Cannot read CMDB person mapping fixture*'
            Test-Path -LiteralPath $fixturePath | Should -BeFalse
            New-Item -Path $fixturePath -ItemType Directory | Out-Null
            { Get-ParCmdbPersonMapping } | Should -Throw '*Cannot read CMDB person mapping fixture*'
            Remove-Item -LiteralPath $fixturePath
        }

        It 'uses the default mapping independently of the working directory' {
            Remove-Module ParData
            Push-Location $TestDrive
            try {
                Import-Module $modulePath -Force
                $rows = @(Get-ParCmdbPersonMapping)
            }
            finally { Pop-Location }
            $rows | Should -HaveCount 5
            $rows[0].personReference | Should -BeExactly 'COMPARE-PERSON-ALEX'
        }

        It 'honors shared configuration then explicit overrides without retargeting other sources' {
            $global:PAR_FixturePaths = @{ PersonMapping = (Join-Path $TestDrive 'missing.csv') }
            Remove-Module ParData
            Import-Module $modulePath -Force
            { Get-ParCmdbPersonMapping } | Should -Throw '*Cannot read*'
            Remove-Module ParData
            Import-Module $modulePath -ArgumentList @{ PersonMapping = $fixturePath } -Force
            (Get-ParCmdbPersonMapping).personReference | Should -BeExactly $mapping.personReference
            @(Get-ParCmdbAsset) | Should -HaveCount 11
        }

        It 'anchors a relative path at import and rereads contents without reimporting' {
            Remove-Module ParData
            Push-Location $TestDrive
            try { Import-Module $modulePath -ArgumentList @{ PersonMapping = './mapping[1].csv' } -Force }
            finally { Pop-Location }
            $mapping.personReference = 'updated'
            $mapping | Export-Csv -LiteralPath $fixturePath -NoTypeInformation
            (Get-ParCmdbPersonMapping).personReference | Should -BeExactly 'updated'
        }

        It 'rejects invalid configured paths in either layer' {
            foreach ($value in @($null, '', '   ', 42)) {
                Remove-Module ParData -ErrorAction SilentlyContinue
                $global:PAR_FixturePaths = @{ PersonMapping = $value }
                { Import-Module $modulePath -Force -ErrorAction Stop } | Should -Throw '*must be a nonblank string*'
                Remove-Variable -Name PAR_FixturePaths -Scope Global
                { Import-Module $modulePath -ArgumentList @{ PersonMapping = $value } -Force -ErrorAction Stop } | Should -Throw '*must be a nonblank string*'
            }
        }
    }
}
