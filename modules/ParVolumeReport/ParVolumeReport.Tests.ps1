BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'ParVolumeReport.psd1') -Force
}

AfterAll {
    Remove-Module ParVolumeReport -ErrorAction SilentlyContinue
}

Describe 'Volume assessment rule' {
    It 'distinguishes below, exactly at, and above the threshold' {
        $rows = @(Get-ParVolumeAssessment -Volume (Get-ParDemoVolume) -MinimumFreePercent 20)

        $rows | Should -HaveCount 3
        $rows.Name | Should -Be @('Demo-C', 'Demo-D', 'Demo-E')
        $rows.FreePercent | Should -Be @(10, 20, 60)
        $rows.Status | Should -Be @('Low', 'OK', 'OK')
    }

    It 'returns the same result twice without altering its inputs' {
        $volumes = @(Get-ParDemoVolume)
        $before = $volumes | ConvertTo-Json

        $first = Get-ParVolumeAssessment -Volume $volumes -MinimumFreePercent 30
        $second = Get-ParVolumeAssessment -Volume $volumes -MinimumFreePercent 30

        ($first | ConvertTo-Json) | Should -BeExactly ($second | ConvertTo-Json)
        ($volumes | ConvertTo-Json) | Should -BeExactly $before
        $first[0].Name = 'Changed result'
        $volumes[0].Name | Should -BeExactly 'Demo-C'
        $second[0].Name | Should -BeExactly 'Demo-C'
    }

    It 'uses the unrounded percentage for comparison' {
        $volume = [pscustomobject]@{ Name = 'Fraction'; CapacityGB = 300; FreeGB = 59 }

        $row = Get-ParVolumeAssessment -Volume $volume -MinimumFreePercent 20

        $row.FreePercent | Should -BeLessThan 20
        $row.FreePercent | Should -BeGreaterThan 19
        $row.Status | Should -BeExactly 'Low'
    }

    It 'accepts empty input and the supported threshold extremes' {
        @(Get-ParVolumeAssessment -Volume @() -MinimumFreePercent 20) | Should -HaveCount 0
        (Get-ParVolumeAssessment -Volume (Get-ParDemoVolume) -MinimumFreePercent 0).Status |
            Should -Be @('OK', 'OK', 'OK')
        (Get-ParVolumeAssessment -Volume (Get-ParDemoVolume) -MinimumFreePercent 100).Status |
            Should -Be @('Low', 'Low', 'Low')
    }
}

Describe 'Report composition' {
    It 'supplies the shared default threshold and permits an override' {
        (Get-ParVolumeReport).Status | Should -Be @('Low', 'OK', 'OK')
        (Get-ParVolumeReport -MinimumFreePercent 30).Status | Should -Be @('Low', 'Low', 'OK')
    }

    It 'invokes an alternate reader once and assesses only its output' {
        $calls = @{ Count = 0 }
        $reader = {
            $calls.Count++
            [pscustomobject]@{ Name = 'Alternate'; CapacityGB = 80; FreeGB = 20 }
        }

        $rows = @(Get-ParVolumeReport -ReadVolume $reader -MinimumFreePercent 30)

        $calls.Count | Should -Be 1
        $rows | Should -HaveCount 1
        $rows[0].Name | Should -BeExactly 'Alternate'
        $rows[0].FreePercent | Should -Be 25
        $rows[0].Status | Should -BeExactly 'Low'
    }

    It 'does not replace an empty source with demonstration volumes' {
        @(Get-ParVolumeReport -ReadVolume { }) | Should -HaveCount 0
    }

    It 'propagates a failed read rather than reporting an empty or healthy result' {
        { Get-ParVolumeReport -ReadVolume { throw 'Reader unavailable' } } |
            Should -Throw '*Reader unavailable*'
    }

    It 'rejects a threshold outside the supported range' {
        { Get-ParVolumeReport -MinimumFreePercent -1 } | Should -Throw
        { Get-ParVolumeReport -MinimumFreePercent 101 } | Should -Throw
    }
}
