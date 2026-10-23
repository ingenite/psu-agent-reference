BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot 'Invoke-GitSettingsApi.ps1'
}

Describe 'Invoke-GitSettingsApi' {
    BeforeEach {
        $connection = @{
            ComputerName = 'https://psu.example.test'
            AppToken = 'synthetic-api-token'
        }
        Mock Invoke-RestMethod {
            [pscustomobject]@{ id = 7; name = 'production'; additionalField = 'preserved' }
        }
    }

    It 'lists settings by default and preserves the API response' {
        $result = & $scriptPath @connection

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Get' -and $Uri -eq 'https://psu.example.test/api/v1/git/settings' -and
            $Headers.Authorization -eq 'Bearer synthetic-api-token' -and
            $MaximumRedirection -eq 0 -and $ErrorAction -eq 'Stop' -and -not $Body
        }
        $result.additionalField | Should -Be 'preserved'
        $result | ConvertTo-Json | Should -Not -Match 'synthetic-api-token'
    }

    It 'saves named settings with numeric enums and a boolean external Git value' {
        $configuration = @{
            Name = 'déploiement "production"'
            Remote = 'git@github.com:example/psu.git'
            Branch = 'main'
            SyncBehavior = 'OneWay'
            Mode = 'Automatic'
            Interval = 60
            ExternalGit = $true
            GitSshKey = 'example-key-reference'
        }
        & $scriptPath @connection -Save @configuration | Out-Null

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $payload = $Body | ConvertFrom-Json -AsHashtable
            $Method -eq 'Post' -and $Uri -eq 'https://psu.example.test/api/v1/git/settings' -and
            $ContentType -eq 'application/json; charset=utf-8' -and
            $payload.name -eq 'déploiement "production"' -and
            $payload.remote -eq 'git@github.com:example/psu.git' -and $payload.branch -eq 'main' -and
            $payload.syncBehavior -eq 1 -and $payload.mode -eq 1 -and $payload.interval -eq 60 -and
            $payload.externalGit -eq $true -and $payload.externalGit -is [bool] -and
            $payload.gitSshKey -eq 'example-key-reference' -and -not $payload.ContainsKey('id')
        }
    }

    It 'maps each supported sync behavior' -ForEach @(
        @{ Behavior = 'TwoWay'; Expected = 0 }
        @{ Behavior = 'OneWay'; Expected = 1 }
        @{ Behavior = 'PushOnly'; Expected = 2 }
    ) {
        & $scriptPath @connection -Save -SyncBehavior $Behavior | Out-Null

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            ($Body | ConvertFrom-Json).syncBehavior -eq $Expected
        }
    }

    It 'updates using the ID in the body and lets named parameters override the copied settings' {
        $settings = @{
            id = 7
            branch = 'old'
            mode = 1
            externalGit = $true
            paused = $false
            proxyUrl = $null
            gitEnvironmentVariables = @('GIT_TERMINAL_PROMPT=0', 'EXAMPLE=value')
            futureField = @{ nested = @{ enabled = $true } }
        }
        & $scriptPath @connection -Save -Settings $settings -Branch 'new' -Mode Manual -ExternalGit:$false | Out-Null

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $payload = $Body | ConvertFrom-Json -AsHashtable
            $Method -eq 'Post' -and $Uri -eq 'https://psu.example.test/api/v1/git/settings' -and
            $payload.id -eq 7 -and $payload.branch -eq 'new' -and $payload.mode -eq 0 -and
            $payload.externalGit -eq $false -and $payload.externalGit -is [bool] -and
            $payload.paused -eq $false -and $payload.ContainsKey('proxyUrl') -and
            $null -eq $payload.proxyUrl -and $payload.gitEnvironmentVariables.Count -eq 2 -and
            $payload.futureField.nested.enabled -eq $true
        }
        $settings.branch | Should -Be 'old'
        $settings.mode | Should -Be 1
        $settings.externalGit | Should -BeTrue
    }

    It 'uses a named ID in the save body without adding defaults' {
        & $scriptPath @connection -Save -Id 7 -Name 'renamed' | Out-Null

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $payload = $Body | ConvertFrom-Json -AsHashtable
            $payload.id -eq 7 -and $payload.name -eq 'renamed' -and $payload.Count -eq 2
        }
    }

    It 'deletes settings using the ID in the URL' {
        & $scriptPath @connection -Delete -Id 7 | Out-Null

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Delete' -and $Uri -eq 'https://psu.example.test/api/v1/git/settings/7' -and -not $Body
        }
    }

    It 'accepts a server URL with a path prefix and trailing slash' {
        $connection.ComputerName = 'https://psu.example.test/instance/'
        & $scriptPath @connection | Out-Null

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'https://psu.example.test/instance/api/v1/git/settings'
        }
    }

    It 'sends no request for a write operation under WhatIf' -ForEach @(
        @{ Operation = @{ Save = $true; Name = 'preview' } }
        @{ Operation = @{ Delete = $true; Id = 7 } }
    ) {
        & $scriptPath @connection @Operation -WhatIf

        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
    }

    It 'still executes read requests under WhatIf' {
        & $scriptPath @connection -WhatIf | Out-Null

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'Get' }
    }

    It 'rejects operations or fields that do not belong together' -ForEach @(
        @{ Operation = @{ Save = $true; Delete = $true; Id = 7 } }
        @{ Operation = @{ Delete = $true; Id = 7; Settings = @{ paused = $true } } }
        @{ Operation = @{ Id = 7 } }
    ) {
        { & $scriptPath @connection @Operation } | Should -Throw

        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
    }

    It 'rejects a false operation switch' -ForEach @(
        @{ Operation = @{ Save = $false } }
        @{ Operation = @{ Delete = $false; Id = 7 } }
    ) {
        { & $scriptPath @connection @Operation } | Should -Throw

        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
    }

    It 'rejects invalid named IDs' -ForEach @(
        @{ InvalidId = 0 }
        @{ InvalidId = -1 }
    ) {
        { & $scriptPath @connection -Delete -Id $InvalidId } | Should -Throw

        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
    }

    It 'rejects an unknown named enum value' {
        { & $scriptPath @connection -Save -SyncBehavior 'Unknown' } | Should -Throw

        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
    }

    It 'propagates API failures to the caller' {
        Mock Invoke-RestMethod { throw 'Synthetic API failure' }

        { & $scriptPath @connection } | Should -Throw '*Synthetic API failure*'
    }
}
