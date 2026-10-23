BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot 'Invoke-SshKeyApi.ps1'
}

Describe 'Invoke-SshKeyApi' {
    BeforeEach {
        $connection = @{
            ComputerName = 'https://psu.example.test'
            AppToken = 'synthetic-api-token'
        }
        Mock Invoke-RestMethod {
            [pscustomobject]@{
                id = 7
                name = 'example-key'
                publicKey = 'synthetic-public-key'
                additionalField = 'preserved'
            }
        }
    }

    It 'lists keys by default and returns all response fields' {
        $result = & $scriptPath @connection

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Get' -and $Uri -eq 'https://psu.example.test/api/v1/sshkey' -and
            $Headers.Authorization -eq 'Bearer synthetic-api-token' -and
            $MaximumRedirection -eq 0 -and $ErrorAction -eq 'Stop' -and -not $Body
        }
        $result.id | Should -Be 7
        $result.publicKey | Should -Be 'synthetic-public-key'
        $result.additionalField | Should -Be 'preserved'
        $result | ConvertTo-Json | Should -Not -Match 'synthetic-api-token'
    }

    It 'retrieves a key using the ID in the URL' {
        & $scriptPath @connection -Id 7 | Out-Null

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Get' -and $Uri -eq 'https://psu.example.test/api/v1/sshkey/7' -and -not $Body
        }
    }

    It 'creates a key with a JSON name and preserves special characters' {
        & $scriptPath @connection -Create -Name 'déploiement "production"' | Out-Null

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $payload = $Body | ConvertFrom-Json
            $Method -eq 'Post' -and $Uri -eq 'https://psu.example.test/api/v1/sshkey' -and
            $ContentType -eq 'application/json; charset=utf-8' -and
            $payload.name -eq 'déploiement "production"' -and
            @($payload.PSObject.Properties.Name).Count -eq 1
        }
    }

    It 'updates a name using the ID in the JSON body' {
        & $scriptPath @connection -Update -Id 7 -Name 'production' | Out-Null

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $payload = $Body | ConvertFrom-Json
            $Method -eq 'Put' -and $Uri -eq 'https://psu.example.test/api/v1/sshkey' -and
            $ContentType -eq 'application/json; charset=utf-8' -and
            $payload.id -eq 7 -and $payload.name -eq 'production' -and
            @($payload.PSObject.Properties.Name).Count -eq 2
        }
    }

    It 'deletes a key using the ID in the URL' {
        & $scriptPath @connection -Delete -Id 7 | Out-Null

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Delete' -and $Uri -eq 'https://psu.example.test/api/v1/sshkey/7' -and -not $Body
        }
    }

    It 'accepts a server URL with a path prefix and trailing slash' {
        $connection.ComputerName = 'https://psu.example.test/instance/'
        & $scriptPath @connection | Out-Null

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'https://psu.example.test/instance/api/v1/sshkey'
        }
    }

    It 'sends no request for a write operation under WhatIf' -ForEach @(
        @{ Operation = @{ Create = $true; Name = 'preview' } }
        @{ Operation = @{ Update = $true; Id = 7; Name = 'preview' } }
        @{ Operation = @{ Delete = $true; Id = 7 } }
    ) {
        $result = & $scriptPath @connection @Operation -WhatIf

        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
        $result | Should -BeNullOrEmpty
    }

    It 'still executes read requests under WhatIf' {
        & $scriptPath @connection -WhatIf | Out-Null

        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'Get' }
    }

    It 'rejects conflicting operations before sending a request' {
        { & $scriptPath @connection -Create -Delete -Name 'example' -Id 7 } | Should -Throw

        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
    }

    It 'rejects a false operation switch before sending a request' -ForEach @(
        @{ Operation = @{ Create = $false; Name = 'example' } }
        @{ Operation = @{ Update = $false; Id = 7; Name = 'example' } }
        @{ Operation = @{ Delete = $false; Id = 7 } }
    ) {
        { & $scriptPath @connection @Operation } | Should -Throw

        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
    }

    It 'rejects invalid IDs before sending a request' -ForEach @(
        @{ InvalidId = 0 }
        @{ InvalidId = -1 }
    ) {
        { & $scriptPath @connection -Delete -Id $InvalidId } | Should -Throw

        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
    }

    It 'rejects an empty name before sending a request' {
        { & $scriptPath @connection -Create -Name '' } | Should -Throw

        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
    }

    It 'propagates API failures to the caller' {
        Mock Invoke-RestMethod { throw 'Synthetic API failure' }

        { & $scriptPath @connection } | Should -Throw '*Synthetic API failure*'
    }
}
