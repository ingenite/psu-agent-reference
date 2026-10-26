Describe 'New-FakeEntraUser' {
    BeforeAll {
        $factoryPath = Join-Path $PSScriptRoot 'New-FakeEntraUser.ps1'
    }

    It 'returns one actual SDK user with a generated ID and unspecified optional fields' {
        $users = @(& $factoryPath -DisplayName 'Alex Example')

        $users | Should -HaveCount 1
        $user = $users[0]
        ($user -is [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser]) | Should -BeTrue
        $user.Id | Should -Match '^[0-9a-f-]{36}$'
        $user.DisplayName | Should -BeExactly 'Alex Example'
        foreach ($property in @('UserPrincipalName', 'Mail', 'AccountEnabled')) {
            ($null -eq $user.$property) | Should -BeTrue
        }
        $second = & $factoryPath -DisplayName 'Alex Example'
        $second.Id | Should -Not -Be $user.Id
    }

    It 'retains supplied opaque identity and descriptive values on repeated construction' {
        $parameters = @{
            Id = '10000000-0000-4000-8000-000000000001'
            DisplayName = 'Alex Example'
            UserPrincipalName = 'alex.signin@example.invalid'
            Mail = 'alex.mail@example.invalid'
            AccountEnabled = $false
        }
        foreach ($attempt in 1..2) {
            $user = & $factoryPath @parameters
            foreach ($property in $parameters.Keys) {
                $user.$property | Should -Be $parameters[$property]
            }
            $user.AccountEnabled | Should -BeOfType [bool]
            $user.AccountEnabled | Should -BeFalse
        }
        $opaque = & $factoryPath -DisplayName 'Alex Example' -Id 'synthetic-entra-user-A'
        $opaque.Id | Should -BeExactly 'synthetic-entra-user-A'
    }

    It 'keeps identity separate when names, UPNs, and mail are shared' {
        $parameters = @{
            DisplayName = 'Alex Example'
            UserPrincipalName = 'alex@example.invalid'
            Mail = 'alex@example.invalid'
        }
        $first = & $factoryPath @parameters -Id '10000000-0000-4000-8000-000000000001'
        $second = & $factoryPath @parameters -Id '10000000-0000-4000-8000-000000000002'

        $first.Id | Should -Not -Be $second.Id
        $first.Id | Should -Not -Be $first.UserPrincipalName
    }

    It 'preserves <Name> optional strings without inference or trimming' -ForEach @(
        @{ Name = 'null'; Value = $null },
        @{ Name = 'empty'; Value = '' },
        @{ Name = 'whitespace'; Value = '   ' }
    ) {
        $user = & $factoryPath -DisplayName 'Blair Sample' -UserPrincipalName $Value -Mail $Value

        foreach ($property in @('UserPrincipalName', 'Mail')) {
            if ($null -eq $Value) {
                ($null -eq $user.$property) | Should -BeTrue
            } else {
                $user.$property | Should -BeExactly $Value
            }
        }
    }

    It 'does not derive mail from UPN or UPN from mail' {
        $withUpn = & $factoryPath -DisplayName 'Alex Example' -UserPrincipalName 'alex@example.invalid'
        $withMail = & $factoryPath -DisplayName 'Alex Example' -Mail 'alex@example.invalid'

        ($null -eq $withUpn.Mail) | Should -BeTrue
        ($null -eq $withMail.UserPrincipalName) | Should -BeTrue
    }

    It 'preserves <Name> account state through an SDK JSON round trip' -ForEach @(
        @{ Name = 'enabled'; Value = $true },
        @{ Name = 'disabled'; Value = $false },
        @{ Name = 'unspecified'; Value = $null }
    ) {
        $user = & $factoryPath -DisplayName 'Casey Demo' -AccountEnabled $Value
        # Session approval covers offline SDK serialization and construction in tests.
        $restored = [Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser]::FromJsonString($user.ToJsonString())

        $restored.Id | Should -BeExactly $user.Id
        ($null -eq $restored.Mail) | Should -BeTrue
        if ($null -eq $Value) {
            ($null -eq $user.AccountEnabled) | Should -BeTrue
            ($null -eq $restored.AccountEnabled) | Should -BeTrue
        } else {
            $user.AccountEnabled | Should -BeOfType [bool]
            $user.AccountEnabled | Should -Be $Value
            $restored.AccountEnabled | Should -Be $Value
        }
    }

    It 'rejects invalid <Name>' -ForEach @(
        @{ Name = 'null ID'; Parameters = @{ Id = $null } },
        @{ Name = 'empty ID'; Parameters = @{ Id = '' } },
        @{ Name = 'blank ID'; Parameters = @{ Id = '   ' } },
        @{ Name = 'numeric ID'; Parameters = @{ Id = 42 } },
        @{ Name = 'null display name'; Parameters = @{ DisplayName = $null } },
        @{ Name = 'empty display name'; Parameters = @{ DisplayName = '' } },
        @{ Name = 'blank display name'; Parameters = @{ DisplayName = ' ' } },
        @{ Name = 'numeric display name'; Parameters = @{ DisplayName = 42 } },
        @{ Name = 'numeric UPN'; Parameters = @{ UserPrincipalName = 42 } },
        @{ Name = 'array mail'; Parameters = @{ Mail = @('a', 'b') } },
        @{ Name = 'string Boolean'; Parameters = @{ AccountEnabled = 'False' } },
        @{ Name = 'numeric Boolean'; Parameters = @{ AccountEnabled = 0 } },
        @{ Name = 'empty Boolean'; Parameters = @{ AccountEnabled = '' } }
    ) {
        $arguments = @{ DisplayName = 'Alex Example' }
        foreach ($key in $Parameters.Keys) { $arguments[$key] = $Parameters[$key] }

        { & $factoryPath @arguments } | Should -Throw
    }
}
