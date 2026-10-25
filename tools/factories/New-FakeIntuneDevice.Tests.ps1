Describe 'New-FakeIntuneDevice' {
    BeforeAll {
        $factoryPath = Join-Path $PSScriptRoot 'New-FakeIntuneDevice.ps1'
    }

    It 'returns one SDK model with separate generated identifiers and Windows defaults' {
        $devices = @(& $factoryPath -DeviceName 'SYNTH-WIN-001')

        $devices | Should -HaveCount 1
        $device = $devices[0]
        ($device -is [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphManagedDevice]) | Should -BeTrue
        $device.Id | Should -Match '^[0-9a-f-]{36}$'
        $device.AzureAdDeviceId | Should -Not -Be $device.Id
        $device.DeviceName | Should -BeExactly 'SYNTH-WIN-001'
        $device.OperatingSystem | Should -BeExactly 'Windows'
        ($null -eq $device.UserId) | Should -BeTrue
        ([string] $device.DeviceEnrollmentType) | Should -BeNullOrEmpty
        $serialized = $device.ToJsonString() | ConvertFrom-Json -AsHashtable
        @($serialized.Keys) | Should -Not -Contain 'deviceEnrollmentType'
        ($device.EnrolledDateTime -le $device.LastSyncDateTime) | Should -BeTrue
    }

    It 'preserves supplied identifiers, user details, hardware, and UTC timestamp instants' {
        $parameters = @{
            Id = '20000000-0000-4000-8000-000000000001'
            AzureAdDeviceId = '30000000-0000-4000-8000-000000000001'
            UserId = '10000000-0000-4000-8000-000000000001'
            DeviceName = 'SYNTH-LAPTOP-001'
            EnrolledDateTime = '2026-09-01T05:00:00-07:00'
            LastSyncDateTime = '2026-10-24T11:30:00-07:00'
            OperatingSystem = 'Windows'
            OSVersion = '10.0.26100.0'
            EmailAddress = 'alex@example.invalid'
            UserPrincipalName = 'alex@example.invalid'
            UserDisplayName = 'Alex Example'
            Manufacturer = 'Fictional Devices'
            Model = 'Synthetic Workstation'
            SerialNumber = 'SYNTH-000001'
            DeviceEnrollmentType = 'unknown'
        }

        $device = & $factoryPath @parameters

        foreach ($propertyName in $parameters.Keys | Where-Object { $_ -notin @('EnrolledDateTime', 'LastSyncDateTime') }) {
            ([string] $device.$propertyName) | Should -BeExactly ([string] $parameters[$propertyName])
        }
        $device.EnrolledDateTime.ToUniversalTime().ToString('o') | Should -BeExactly '2026-09-01T12:00:00.0000000Z'
        $device.LastSyncDateTime.ToUniversalTime().ToString('o') | Should -BeExactly '2026-10-24T18:30:00.0000000Z'
    }

    It 'preserves a <Name> user association' -ForEach @(
        @{ Name = 'null'; Value = $null },
        @{ Name = 'empty'; Value = '' },
        @{ Name = 'whitespace'; Value = '   ' }
    ) {
        $device = & $factoryPath -DeviceName 'SYNTH-UNASSIGNED' -UserId $Value

        if ($null -eq $Value) {
            ($null -eq $device.UserId) | Should -BeTrue
        }
        else {
            $device.UserId | Should -BeExactly $Value
        }
    }

    It 'rejects a last sync before enrollment' {
        {
            & $factoryPath -DeviceName 'SYNTH-INVALID' -EnrolledDateTime '2026-10-24T18:30:00Z' `
                -LastSyncDateTime '2026-09-01T12:00:00Z'
        } | Should -Throw '*LastSyncDateTime must be on or after EnrolledDateTime*'
    }

    It 'omits an empty enrollment type' {
        $device = & $factoryPath -DeviceName 'SYNTH-NO-ENROLLMENT' -DeviceEnrollmentType ''

        $serialized = $device.ToJsonString() | ConvertFrom-Json -AsHashtable
        @($serialized.Keys) | Should -Not -Contain 'deviceEnrollmentType'
    }

    It 'rejects non-string user association values' {
        { & $factoryPath -DeviceName 'SYNTH-INVALID' -UserId 42 } | Should -Throw
    }
}
