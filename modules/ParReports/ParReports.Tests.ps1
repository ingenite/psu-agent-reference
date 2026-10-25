BeforeAll {
    $reportModulePath = Join-Path $PSScriptRoot 'ParReports.psd1'
    $dataModulePath = Join-Path $PSScriptRoot '../ParData/ParData.psd1'
    $factoryPath = Join-Path $PSScriptRoot '../../tools/factories/New-FakeIntuneDevice.ps1'
    $existingFixtureVariable = Get-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
    Remove-Module ParReports, ParData -ErrorAction SilentlyContinue
    Import-Module $reportModulePath -Force

    function New-TestIntuneDevice {
        param(
            [AllowNull()]
            [AllowEmptyString()]
            $UserId = $null,

            [AllowNull()]
            [AllowEmptyString()]
            $OperatingSystem = 'Windows'
        )

        [pscustomobject][ordered]@{
            Id = '20000000-0000-4000-8000-000000000001'
            AzureAdDeviceId = '30000000-0000-4000-8000-000000000001'
            DeviceName = 'SYNTH-REPORT-001'
            SerialNumber = 'SYNTH-000001'
            Manufacturer = 'Fictional Devices'
            Model = 'Synthetic Laptop'
            OperatingSystem = $OperatingSystem
            OSVersion = '10.0.26100.0'
            DeviceEnrollmentType = 'unknown'
            EnrolledDateTime = [datetime] '2026-09-01T12:00:00Z'
            LastSyncDateTime = [datetime] '2026-10-24T18:30:00Z'
            UserId = $UserId
            UserDisplayName = 'Alex Example'
            EmailAddress = 'alex@example.invalid'
            UserPrincipalName = 'alex@example.invalid'
        }
    }
}

AfterAll {
    Remove-Module ParReports, ParData -ErrorAction SilentlyContinue
    if ($null -ne $existingFixtureVariable) {
        Set-Variable -Name 'PAR_FixturePaths' -Scope Global -Value $existingFixtureVariable.Value
    }
}

Describe 'ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport' {
    It 'selects a <Name> user ID despite populated display name, email, and UPN' -ForEach @(
        @{ Name = 'null'; UserId = $null },
        @{ Name = 'empty'; UserId = '' },
        @{ Name = 'spaces'; UserId = '   ' },
        @{ Name = 'mixed whitespace'; UserId = " `t`r`n" }
    ) {
        $device = New-TestIntuneDevice -UserId $UserId

        $rows = @($device | ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport)

        $rows | Should -HaveCount 1
        $rows[0].IntuneDeviceId | Should -BeExactly $device.Id
        if ($null -eq $UserId) {
            ($null -eq $rows[0].UserId) | Should -BeTrue
        }
        else {
            $rows[0].UserId | Should -BeExactly $UserId
        }
    }

    It 'excludes a nonblank user ID even when user display fields are missing' {
        $device = New-TestIntuneDevice -UserId ' 10000000-0000-4000-8000-000000000001 '
        $device.UserDisplayName = $null
        $device.EmailAddress = ''
        $device.UserPrincipalName = '   '

        @($device | ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport) | Should -HaveCount 0
    }

    It 'excludes the <Name> OS label even with no user ID' -ForEach @(
        @{ Name = 'Android'; OperatingSystem = 'Android' },
        @{ Name = 'iOS'; OperatingSystem = 'iOS' },
        @{ Name = 'macOS'; OperatingSystem = 'macOS' },
        @{ Name = 'missing'; OperatingSystem = $null },
        @{ Name = 'empty'; OperatingSystem = '' },
        @{ Name = 'whitespace'; OperatingSystem = '   ' },
        @{ Name = 'prefixed Windows'; OperatingSystem = 'WindowsPhone' },
        @{ Name = 'versioned Windows'; OperatingSystem = 'Windows 11' }
    ) {
        $device = New-TestIntuneDevice -OperatingSystem $OperatingSystem

        @($device | ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport) | Should -HaveCount 0
    }

    It 'matches Windows case-insensitively and preserves the source OS label' {
        $device = New-TestIntuneDevice -OperatingSystem 'windows'

        $rows = @(ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport -InputObject $device)

        $rows | Should -HaveCount 1
        $rows[0].OperatingSystem | Should -BeExactly 'windows'
    }

    It 'returns the documented field set with original identifiers, hardware, OS, enrollment, and sync context' {
        $device = New-TestIntuneDevice

        $row = $device | ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport

        $fields = @(
            'IntuneDeviceId', 'AzureAdDeviceId', 'DeviceName', 'SerialNumber',
            'Manufacturer', 'Model', 'OperatingSystem', 'OSVersion',
            'DeviceEnrollmentType', 'EnrolledDateTime', 'LastSyncDateTime', 'UserId'
        )
        @($row.PSObject.Properties.Name) | Should -Be $fields
        $row.IntuneDeviceId | Should -BeExactly $device.Id
        $row.AzureAdDeviceId | Should -Not -Be $row.IntuneDeviceId
        foreach ($field in $fields | Where-Object { $_ -ne 'IntuneDeviceId' }) {
            $row.$field | Should -Be $device.$field
        }
        $row.EnrolledDateTime | Should -BeOfType [datetime]
        $row.LastSyncDateTime | Should -BeOfType [datetime]
    }

    It 'preserves missing optional hardware, timestamps, and identifiers without guessing values' {
        $device = New-TestIntuneDevice
        foreach ($field in @('AzureAdDeviceId', 'SerialNumber', 'Manufacturer', 'Model', 'OSVersion', 'EnrolledDateTime', 'LastSyncDateTime')) {
            $device.$field = $null
        }
        $device.DeviceEnrollmentType = $null

        $row = $device | ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport

        foreach ($field in @('AzureAdDeviceId', 'SerialNumber', 'Manufacturer', 'Model', 'OSVersion', 'EnrolledDateTime', 'LastSyncDateTime')) {
            ($null -eq $row.$field) | Should -BeTrue
        }
        $row.DeviceEnrollmentType | Should -BeExactly ''
    }

    It 'returns no rows for an explicitly empty array, null, an empty pipeline, or null elements' {
        @(ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport -InputObject @()) | Should -HaveCount 0
        @(ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport -InputObject $null) | Should -HaveCount 0
        @(@() | ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport) | Should -HaveCount 0
        @(ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport -InputObject @($null, $null)) | Should -HaveCount 0
    }

    It 'preserves matching source order and duplicates for both array and pipeline input' {
        $first = New-TestIntuneDevice
        $second = New-TestIntuneDevice -UserId ''
        $second.Id = '20000000-0000-4000-8000-000000000002'
        $devices = @($first, (New-TestIntuneDevice -UserId 'assigned'), $null, $second, $first)

        $arrayRows = @(ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport -InputObject $devices)
        $pipelineRows = @($devices | ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport)

        $arrayRows | Should -HaveCount 3
        $arrayRows.IntuneDeviceId | Should -Be @($first.Id, $second.Id, $first.Id)
        ($pipelineRows | ConvertTo-Json) | Should -BeExactly ($arrayRows | ConvertTo-Json)
    }

    It 'leaves every source property unchanged and produces independent report objects' {
        $devices = @(
            (New-TestIntuneDevice -UserId " `t"),
            (New-TestIntuneDevice -UserId 'assigned'),
            (New-TestIntuneDevice -OperatingSystem 'Android')
        )
        $before = $devices | ConvertTo-Json

        $rows = @(ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport -InputObject $devices)
        $rows[0].DeviceName = 'EDITED-REPORT-ONLY'
        $rows[0].UserId = 'report-only'

        ($devices | ConvertTo-Json) | Should -BeExactly $before
    }
}

Describe 'Get-ParIntuneDeviceWithoutPrimaryUserReport orchestration' {
    BeforeAll {
        Import-Module $dataModulePath -Force
    }

    BeforeEach {
        Mock Import-Module -ModuleName ParReports {}
    }

    It 'retrieves once and applies the same transformation to the complete source dataset' {
        $devices = @(
            (New-TestIntuneDevice),
            (New-TestIntuneDevice -UserId 'assigned'),
            (New-TestIntuneDevice -OperatingSystem 'Android')
        )
        Mock Get-ParIntuneDevice -ModuleName ParReports { $devices }

        $rows = @(Get-ParIntuneDeviceWithoutPrimaryUserReport)

        $rows | Should -HaveCount 1
        ($rows | ConvertTo-Json) | Should -BeExactly ($devices | ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport | ConvertTo-Json)
        Should -Invoke Get-ParIntuneDevice -ModuleName ParReports -Times 1 -Exactly
    }

    It 'returns no rows when retrieval succeeds with no records' {
        Mock Get-ParIntuneDevice -ModuleName ParReports {}

        @(Get-ParIntuneDeviceWithoutPrimaryUserReport) | Should -HaveCount 0
        Should -Invoke Get-ParIntuneDevice -ModuleName ParReports -Times 1 -Exactly
    }

    It 'returns no rows when all retrieved devices are excluded' {
        Mock Get-ParIntuneDevice -ModuleName ParReports {
            New-TestIntuneDevice -UserId 'assigned'
            New-TestIntuneDevice -OperatingSystem 'Android'
        }

        @(Get-ParIntuneDeviceWithoutPrimaryUserReport) | Should -HaveCount 0
    }

    It 'propagates a retrieval failure instead of returning an empty successful report' {
        Mock Get-ParIntuneDevice -ModuleName ParReports { throw 'Synthetic retrieval failed.' }

        { Get-ParIntuneDeviceWithoutPrimaryUserReport } | Should -Throw '*Synthetic retrieval failed.*'
    }

    It 'emits no partial report when retrieval emits a device then fails' {
        Mock Get-ParIntuneDevice -ModuleName ParReports {
            New-TestIntuneDevice
            throw 'Synthetic later retrieval failure.'
        }
        $received = @()
        $failure = $null

        try {
            Get-ParIntuneDeviceWithoutPrimaryUserReport | ForEach-Object { $received += $_ }
        }
        catch {
            $failure = $_
        }

        $failure.Exception.Message | Should -BeLike '*Synthetic later retrieval failure.*'
        $received | Should -HaveCount 0
    }

    It 'promotes a nonterminating retrieval error even if the caller requests silent errors' {
        InModuleScope ParReports {
            function Get-ParIntuneDevice {
                [CmdletBinding()]
                param()

                Write-Error 'Synthetic nonterminating retrieval failure.'
            }

            { Get-ParIntuneDeviceWithoutPrimaryUserReport -ErrorAction SilentlyContinue } |
                Should -Throw '*Synthetic nonterminating retrieval failure.*'
        }
    }
}

Describe 'ParReports offline provider integration' {
    BeforeEach {
        Remove-Module ParReports, ParData -ErrorAction SilentlyContinue
        Import-Module $reportModulePath -Force
    }

    It 'loads the default provider and reports missing and intentionally userless fixture cases' {
        $rows = @(Get-ParIntuneDeviceWithoutPrimaryUserReport)

        $rows | Should -HaveCount 2
        $rows.DeviceName | Should -Be @('SYNTH-UNASSIGNED-001', 'SYNTH-SHARED-001')
        $rows.IntuneDeviceId | Should -Be @(
            '20000000-0000-4000-8000-000000000002',
            '20000000-0000-4000-8000-000000000003'
        )
        $rows.AzureAdDeviceId | Should -Be @(
            '30000000-0000-4000-8000-000000000002',
            '30000000-0000-4000-8000-000000000003'
        )
        foreach ($row in $rows) {
            $row.DeviceEnrollmentType | Should -BeExactly 'unknown'
            ($null -eq $row.UserId) | Should -BeTrue
            $row.LastSyncDateTime | Should -BeOfType [datetime]
        }
        (Get-Module -All Microsoft.Graph.DeviceManagement | Select-Object -First 1).Version.ToString() | Should -BeExactly '2.41.2'
    }

    It 'honors an existing configured ParData import and propagates its missing-file error' {
        $missingPath = Join-Path $TestDrive 'missing-devices.csv'
        Import-Module $dataModulePath -ArgumentList @{ IntuneDevice = $missingPath } -Force

        { Get-ParIntuneDeviceWithoutPrimaryUserReport } | Should -Throw '*Cannot read Intune device fixture*missing-devices.csv*'
        Test-Path -LiteralPath $missingPath | Should -BeFalse
    }

    It 'transforms factory SDK models without modifying the source model values' {
        $devices = @(
            (& $factoryPath -DeviceName 'SYNTH-SDK-MISSING' -UserId " `t"),
            (& $factoryPath -DeviceName 'SYNTH-SDK-ASSIGNED' -UserId 'assigned'),
            (& $factoryPath -DeviceName 'SYNTH-SDK-ANDROID' -OperatingSystem 'Android')
        )
        $fields = @(
            'Id', 'AzureAdDeviceId', 'DeviceName', 'SerialNumber', 'Manufacturer',
            'Model', 'OperatingSystem', 'OSVersion', 'DeviceEnrollmentType',
            'EnrolledDateTime', 'LastSyncDateTime', 'UserId', 'UserDisplayName',
            'EmailAddress', 'UserPrincipalName'
        )
        $before = $devices | Select-Object -Property $fields | ConvertTo-Json

        $rows = @($devices | ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport)

        $rows | Should -HaveCount 1
        $rows[0].IntuneDeviceId | Should -BeExactly $devices[0].Id
        $rows[0].UserId | Should -BeExactly " `t"
        $rows[0].LastSyncDateTime | Should -Be $devices[0].LastSyncDateTime
        ($devices | Select-Object -Property $fields | ConvertTo-Json) | Should -BeExactly $before
    }
}
