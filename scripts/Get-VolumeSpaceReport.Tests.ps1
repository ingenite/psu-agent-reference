BeforeAll {
    $repositoryRoot = Split-Path $PSScriptRoot -Parent
    $Repository = $repositoryRoot
    $scriptPath = Join-Path $PSScriptRoot 'Get-VolumeSpaceReport.ps1'
    $endpointPath = Join-Path $repositoryRoot 'endpoints/Get-VolumeSpaceReport.ps1'
}

Describe 'Volume-space resource entry points with a supplied PSU repository path' {
    It 'returns the same default and overridden rule results from both resources' {
        foreach ($arguments in @(@{}, @{ MinimumFreePercent = 30 })) {
            $scriptJson = & $scriptPath @arguments
            $scriptJson | Should -BeOfType [string]
            $scriptRows = @($scriptJson | ConvertFrom-Json)
            $endpointRows = @(& $endpointPath @arguments)

            $scriptRows | Should -HaveCount 3
            ($scriptRows | ConvertTo-Json) | Should -BeExactly ($endpointRows | ConvertTo-Json)
            $expected = if ($arguments.Count) { @('Low', 'Low', 'OK') } else { @('Low', 'OK', 'OK') }
            $scriptRows.Status | Should -Be $expected
        }
    }

    It 'loads its dependency independently of the working directory' {
        Push-Location $TestDrive
        try {
            foreach ($resourcePath in @($scriptPath, $endpointPath)) {
                Remove-Module ParVolumeReport -ErrorAction SilentlyContinue
                $result = & $resourcePath
                $rows = if ($resourcePath -eq $scriptPath) { @($result | ConvertFrom-Json) } else { @($result) }
                $rows.Status | Should -Be @('Low', 'OK', 'OK')
            }
        }
        finally {
            Pop-Location
        }
    }
}
