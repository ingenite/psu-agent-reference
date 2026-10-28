Describe 'Export-FakeEntraUser' {
    BeforeAll {
        $factoryPath = Join-Path $PSScriptRoot 'New-FakeEntraUser.ps1'
        $exportPath = Join-Path $PSScriptRoot 'Export-FakeEntraUser.ps1'
        $columns = 'id,displayName,userPrincipalName,mail,accountEnabled'
    }

    It 'exports only the selected columns and round-trips CSV text without changing the model' {
        $path = Join-Path $TestDrive 'nested/users[1].csv'
        $user = & $factoryPath -DisplayName "Example, `"Alex`"`nCafé" `
            -Id '10000000-0000-4000-8000-000000000001' `
            -UserPrincipalName 'alex.signin@example.invalid' -Mail 'alex.mail@example.invalid' -AccountEnabled $false
        $user.Department = 'not exported'
        $before = $user.ToJsonString()

        $output = @($user | & $exportPath -Path $path)
        $rows = @(Import-Csv -LiteralPath $path -Encoding utf8)

        $output | Should -HaveCount 0
        $rows | Should -HaveCount 1
        ($rows[0].PSObject.Properties.Name -join ',') | Should -BeExactly $columns
        foreach ($column in @('id', 'displayName', 'userPrincipalName', 'mail')) {
            $rows[0].$column | Should -BeExactly $user.$column
        }
        $rows[0].accountEnabled | Should -BeExactly 'False'
        $user.ToJsonString() | Should -BeExactly $before
    }

    It 'accepts arrays, preserves input order and duplicate IDs, and replaces previous data' {
        $path = Join-Path $TestDrive 'replace.csv'
        & $factoryPath -DisplayName 'Old User' | & $exportPath -Path $path
        $first = & $factoryPath -DisplayName 'Alex Example'
        $second = & $factoryPath -DisplayName 'Blair Sample'

        & $exportPath -InputObject @($second, $first, $second) -Path $path
        $rows = @(Import-Csv -LiteralPath $path)

        $rows | Should -HaveCount 3
        ($rows.id -join ',') | Should -BeExactly (@($second.Id, $first.Id, $second.Id) -join ',')
    }

    It 'exports true, false, and null distinctly and restores Boolean values explicitly' {
        $path = Join-Path $TestDrive 'booleans.csv'
        @(
            & $factoryPath -DisplayName 'Alex Example' -AccountEnabled $true
            & $factoryPath -DisplayName 'Blair Sample' -AccountEnabled $false
            & $factoryPath -DisplayName 'Casey Demo'
        ) | & $exportPath -Path $path
        $rows = @(Import-Csv -LiteralPath $path)

        $rows[0].accountEnabled | Should -BeExactly 'True'
        $rows[1].accountEnabled | Should -BeExactly 'False'
        $rows[2].accountEnabled | Should -BeExactly ''
        $restored = @(
            foreach ($row in $rows) {
                $properties = [ordered]@{}
                foreach ($column in @('id', 'displayName', 'userPrincipalName', 'mail', 'accountEnabled')) {
                    $value = $row.$column
                    $properties[$column] = if ($value -eq '') { $null }
                    elseif ($column -eq 'accountEnabled') {
                        switch -CaseSensitive ($value) {
                            'True' { $true }
                            'False' { $false }
                            default { throw "Invalid Boolean CSV text: $value" }
                        }
                    } else { $value }
                }
                # Session approval covers offline SDK deserialization in tests.
                [Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser]::FromJsonString(
                    (ConvertTo-Json -InputObject $properties -Depth 3)
                )
            }
        )
        $restored[0].AccountEnabled | Should -BeTrue
        $restored[1].AccountEnabled | Should -BeFalse
        ($null -eq $restored[2].AccountEnabled) | Should -BeTrue
        foreach ($index in 0..2) {
            $restored[$index].Id | Should -BeExactly $rows[$index].id
            ($null -eq $restored[$index].Mail) | Should -BeTrue
        }
    }

    It 'represents null and empty optional strings as empty cells while preserving whitespace' {
        $path = Join-Path $TestDrive 'optional.csv'
        @(
            foreach ($value in @($null, '', '   ')) {
                & $factoryPath -DisplayName 'Casey Demo' -UserPrincipalName $value -Mail $value
            }
        ) | & $exportPath -Path $path
        $rows = @(Import-Csv -LiteralPath $path)

        foreach ($column in @('userPrincipalName', 'mail')) {
            $rows[0].$column | Should -BeExactly ''
            $rows[1].$column | Should -BeExactly ''
            $rows[2].$column | Should -BeExactly '   '
        }
    }

    It 'appends arrays with duplicate IDs while retaining existing rows and one header' {
        $path = Join-Path $TestDrive 'append.csv'
        $first = & $factoryPath -DisplayName 'Alex Example' -AccountEnabled $false
        $first | & $exportPath -Path $path
        $second = & $factoryPath -DisplayName 'Blair Sample'

        & $exportPath -InputObject @($second, $first) -Path $path -Append
        $rows = @(Import-Csv -LiteralPath $path)

        ($rows.id -join ',') | Should -BeExactly (@($first.Id, $second.Id, $first.Id) -join ',')
        $rows[0].accountEnabled | Should -BeExactly 'False'
        @(Get-Content -LiteralPath $path) | Should -HaveCount 4
    }

    It 'creates a missing CSV and parent directory with Append' {
        $path = Join-Path $TestDrive 'append-new/users.csv'

        & $factoryPath -DisplayName 'Alex Example' | & $exportPath -Path $path -Append

        @(Import-Csv -LiteralPath $path) | Should -HaveCount 1
    }

    It 'accepts an unquoted compatible header-only file' {
        $path = Join-Path $TestDrive 'header-only.csv'
        Set-Content -LiteralPath $path -Value $columns

        & $factoryPath -DisplayName 'Alex Example' | & $exportPath -Path $path -Append

        (Import-Csv -LiteralPath $path).displayName | Should -BeExactly 'Alex Example'
        @(Get-Content -LiteralPath $path) | Should -HaveCount 2
    }

    It 'rejects an incompatible <Name> header without changing the file' -ForEach @(
        @{ Name = 'unrelated'; Header = 'unexpected' },
        @{ Name = 'subset'; Header = 'id,displayName' },
        @{ Name = 'superset'; Header = 'id,displayName,userPrincipalName,mail,accountEnabled,extra' },
        @{ Name = 'reordered'; Header = 'displayName,id,userPrincipalName,mail,accountEnabled' }
    ) {
        $path = Join-Path $TestDrive 'incompatible.csv'
        Set-Content -LiteralPath $path -Value $Header
        $before = Get-Content -LiteralPath $path -Raw

        { & $factoryPath -DisplayName 'Alex Example' | & $exportPath -Path $path -Append } |
            Should -Throw '*incompatible*'
        (Get-Content -LiteralPath $path -Raw) | Should -BeExactly $before
    }

    It 'rejects <Name> input before replacing or appending any records' -ForEach @(
        @{ Name = 'null'; Invalid = $null },
        @{ Name = 'plain object'; Invalid = [pscustomobject]@{ Id = 'not-a-model' } }
    ) {
        $path = Join-Path $TestDrive 'unchanged.csv'
        $valid = & $factoryPath -DisplayName 'Alex Example'
        $valid | & $exportPath -Path $path
        $before = Get-Content -LiteralPath $path -Raw

        foreach ($append in @($false, $true)) {
            { @($valid, $Invalid) | & $exportPath -Path $path -Append:$append } | Should -Throw
            (Get-Content -LiteralPath $path -Raw) | Should -BeExactly $before
        }
        $newPath = Join-Path $TestDrive 'not-created/users.csv'
        { & $exportPath -InputObject @($valid, $Invalid) -Path $newPath } | Should -Throw
        Test-Path -LiteralPath (Split-Path $newPath -Parent) | Should -BeFalse
    }

    It 'rejects an SDK model with a missing required source value before writing' {
        $path = Join-Path $TestDrive 'invalid-model.csv'
        $user = & $factoryPath -DisplayName 'Alex Example'
        $user.Id = ''

        { $user | & $exportPath -Path $path } | Should -Throw '*nonblank*'
        Test-Path -LiteralPath $path | Should -BeFalse
    }

    It 'rejects empty arrays and pipelines before changing the destination' {
        $path = Join-Path $TestDrive 'empty.csv'
        Set-Content -LiteralPath $path -Value 'existing data'
        $before = Get-Content -LiteralPath $path -Raw

        { & $exportPath -InputObject @() -Path $path } | Should -Throw '*at least one*'
        { @() | & $exportPath -Path $path } | Should -Throw '*at least one*'
        (Get-Content -LiteralPath $path -Raw) | Should -BeExactly $before
    }

    It 'rejects blank paths and reports filesystem write failures' {
        { & $factoryPath -DisplayName 'Alex Example' | & $exportPath -Path ' ' } | Should -Throw
        { & $factoryPath -DisplayName 'Alex Example' | & $exportPath -Path $TestDrive } | Should -Throw
    }
}

Describe 'Entra user fixture' {
    BeforeAll {
        $factoryPath = Join-Path $PSScriptRoot 'New-FakeEntraUser.ps1'
        $exportPath = Join-Path $PSScriptRoot 'Export-FakeEntraUser.ps1'
        $fixturePath = Join-Path $PSScriptRoot '../../data/test-entra-users.csv'
        $intunePath = Join-Path $PSScriptRoot '../../data/test-intune-devices.csv'
        $cmdbPath = Join-Path $PSScriptRoot '../../data/test-cmdb-assets.csv'
        $users = @(Import-Csv -LiteralPath $fixturePath)
    }

    It 'regenerates the exact versioned fixture twice without modifying existing source fixtures' {
        $path = Join-Path $TestDrive 'generated/entra-users.csv'
        $intuneBefore = Get-Content -LiteralPath $intunePath -Raw
        $cmdbBefore = Get-Content -LiteralPath $cmdbPath -Raw
        $userParameters = @(
            @{
                Id = '10000000-0000-4000-8000-000000000001'
                DisplayName = 'Alex Example'
                UserPrincipalName = 'alex@example.invalid'
                Mail = 'alex@example.invalid'
                AccountEnabled = $true
            }
            @{
                Id = '10000000-0000-4000-8000-000000000002'
                DisplayName = 'Blair Sample'
                UserPrincipalName = 'blair@example.invalid'
                AccountEnabled = $false
            }
            @{
                Id = '10000000-0000-4000-8000-000000000003'
                DisplayName = 'Casey Demo'
            }
        )
        foreach ($attempt in 1..2) {
            $generated = @(
                foreach ($parameters in $userParameters) { & $factoryPath @parameters }
            )
            $generated | & $exportPath -Path $path

            (Get-Content -LiteralPath $path -Raw) | Should -BeExactly (Get-Content -LiteralPath $fixturePath -Raw)
        }
        (Get-Content -LiteralPath $intunePath -Raw) | Should -BeExactly $intuneBefore
        (Get-Content -LiteralPath $cmdbPath -Raw) | Should -BeExactly $cmdbBefore
    }

    It 'contains only five descriptive columns and three distinct stable Entra IDs' {
        $users | Should -HaveCount 3
        @($users.id | Select-Object -Unique) | Should -HaveCount 3
        ($users.id -join ',') | Should -BeExactly (
            '10000000-0000-4000-8000-000000000001,' +
            '10000000-0000-4000-8000-000000000002,10000000-0000-4000-8000-000000000003'
        )
        $cmdbReferences = @((Import-Csv -LiteralPath $cmdbPath).assignedUserReference)
        foreach ($user in $users) {
            ($user.PSObject.Properties.Name -join ',') | Should -BeExactly 'id,displayName,userPrincipalName,mail,accountEnabled'
            $cmdbReferences | Should -Not -Contain $user.id
            $user.id | Should -Not -Be $user.displayName
            $user.id | Should -Not -Be $user.userPrincipalName
            $user.id | Should -Not -Be $user.mail
        }
    }

    It 'includes Alex using the existing Intune association and distinct users with missing values' {
        $device = Import-Csv -LiteralPath $intunePath | Where-Object deviceName -EQ 'SYNTH-ASSIGNED-001'
        $users[0].id | Should -BeExactly $device.userId
        $users[0].displayName | Should -BeExactly 'Alex Example'
        $users[0].userPrincipalName | Should -BeExactly 'alex@example.invalid'
        $users[0].mail | Should -BeExactly 'alex@example.invalid'
        $users[0].accountEnabled | Should -BeExactly 'True'
        $users[1].displayName | Should -BeExactly 'Blair Sample'
        $users[1].mail | Should -BeExactly ''
        $users[1].accountEnabled | Should -BeExactly 'False'
        $users[2].displayName | Should -BeExactly 'Casey Demo'
        $users[2].userPrincipalName | Should -BeExactly ''
        $users[2].mail | Should -BeExactly ''
        $users[2].accountEnabled | Should -BeExactly ''
    }
}
