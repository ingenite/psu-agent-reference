Describe 'Export-FakeIntuneDevice' {
    BeforeAll {
        $factoryPath = Join-Path $PSScriptRoot 'New-FakeIntuneDevice.ps1'
        $exportPath = Join-Path $PSScriptRoot 'Export-FakeIntuneDevice.ps1'
        $common = @{
            EnrolledDateTime = '2026-09-01T05:00:00-07:00'
            LastSyncDateTime = '2026-10-24T11:30:00-07:00'
        }
    }

    It 'exports multiple models with the 15 selected columns and round-trippable CSV text' {
        $path = Join-Path $TestDrive 'nested/intune-devices.csv'
        $devices = @(
            & $factoryPath @common -DeviceName 'SYNTH-ASSIGNED' `
                -Id '20000000-0000-4000-8000-000000000001' `
                -AzureAdDeviceId '30000000-0000-4000-8000-000000000001' `
                -UserId '10000000-0000-4000-8000-000000000001' `
                -UserDisplayName 'Example, Alex' -EmailAddress 'alex@example.invalid' `
                -UserPrincipalName 'alex@example.invalid' -Manufacturer 'Fictional, "Devices"' `
                -DeviceEnrollmentType 'unknown'
            & $factoryPath @common -DeviceName 'SYNTH-UNASSIGNED' -UserId $null
        )

        $devices | & $exportPath -Path $path
        $rows = @(Import-Csv -LiteralPath $path)

        $rows | Should -HaveCount 2
        @($rows[0].PSObject.Properties.Name) | Should -HaveCount 15
        ($rows[0].PSObject.Properties.Name -join ',') | Should -BeExactly (
            'id,userId,deviceName,enrolledDateTime,lastSyncDateTime,operatingSystem,osVersion,' +
            'emailAddress,azureADDeviceId,userPrincipalName,model,manufacturer,serialNumber,' +
            'userDisplayName,deviceEnrollmentType'
        )
        $rows[0].id | Should -BeExactly $devices[0].Id
        $rows[0].azureADDeviceId | Should -BeExactly $devices[0].AzureAdDeviceId
        $rows[0].userId | Should -BeExactly $devices[0].UserId
        $rows[0].userDisplayName | Should -BeExactly 'Example, Alex'
        $rows[0].manufacturer | Should -BeExactly 'Fictional, "Devices"'
        $rows[0].enrolledDateTime | Should -BeExactly '2026-09-01T12:00:00.0000000Z'
        $rows[0].lastSyncDateTime | Should -BeExactly '2026-10-24T18:30:00.0000000Z'
        $rows[0].deviceEnrollmentType | Should -BeExactly 'unknown'
        $rows[1].userId | Should -BeExactly ''
        $rows[1].deviceEnrollmentType | Should -BeExactly ''
    }

    It 'accepts an explicit model array and replaces the previous dataset' {
        $path = Join-Path $TestDrive 'replacement.csv'
        $first = & $factoryPath @common -DeviceName 'SYNTH-FIRST'
        & $exportPath -InputObject $first -Path $path
        $replacement = @(
            & $factoryPath @common -DeviceName 'SYNTH-SECOND'
            & $factoryPath @common -DeviceName 'SYNTH-THIRD'
        )

        & $exportPath -InputObject $replacement -Path $path
        $rows = @(Import-Csv -LiteralPath $path)

        $rows | Should -HaveCount 2
        $rows[0].deviceName | Should -BeExactly 'SYNTH-SECOND'
        $rows[1].deviceName | Should -BeExactly 'SYNTH-THIRD'
    }

    It 'represents both null and empty user IDs as empty CSV cells' {
        $path = Join-Path $TestDrive 'missing-users.csv'
        @(
            & $factoryPath @common -DeviceName 'SYNTH-NULL' -UserId $null
            & $factoryPath @common -DeviceName 'SYNTH-EMPTY' -UserId ''
        ) | & $exportPath -Path $path

        foreach ($row in Import-Csv -LiteralPath $path) {
            $row.userId | Should -BeExactly ''
        }
    }

    It 'appends new rows while retaining existing rows and one header' {
        $path = Join-Path $TestDrive 'append.csv'
        & $factoryPath @common -DeviceName 'SYNTH-FIRST' | & $exportPath -Path $path

        & $factoryPath @common -DeviceName 'SYNTH-SECOND' | & $exportPath -Path $path -Append
        $rows = @(Import-Csv -LiteralPath $path)

        $rows | Should -HaveCount 2
        $rows[0].deviceName | Should -BeExactly 'SYNTH-FIRST'
        $rows[1].deviceName | Should -BeExactly 'SYNTH-SECOND'
        @(Get-Content -LiteralPath $path) | Should -HaveCount 3
    }

    It 'creates a missing CSV when appending' {
        $path = Join-Path $TestDrive 'append-new/devices.csv'

        & $factoryPath @common -DeviceName 'SYNTH-NEW' | & $exportPath -Path $path -Append
        $rows = @(Import-Csv -LiteralPath $path)

        $rows | Should -HaveCount 1
        $rows[0].deviceName | Should -BeExactly 'SYNTH-NEW'
    }

    It 'rejects append to an incompatible header without changing the file' {
        $path = Join-Path $TestDrive 'incompatible.csv'
        Set-Content -LiteralPath $path -Value @('unexpected', 'existing data')
        $original = Get-Content -LiteralPath $path -Raw

        {
            & $factoryPath @common -DeviceName 'SYNTH-NEW' | & $exportPath -Path $path -Append
        } | Should -Throw
        (Get-Content -LiteralPath $path -Raw) | Should -BeExactly $original
    }

    It 'can restore the SDK model from CSV after normalizing empty cells' {
        $path = Join-Path $TestDrive 'restore.csv'
        $device = & $factoryPath @common -DeviceName 'SYNTH-RESTORE' -DeviceEnrollmentType 'unknown'
        $device | & $exportPath -Path $path
        $row = Import-Csv -LiteralPath $path
        $properties = [ordered]@{}
        foreach ($property in $row.PSObject.Properties) {
            $properties[$property.Name] = if ($property.Value -eq '') { $null } else { $property.Value }
        }

        $restored = [Microsoft.Graph.PowerShell.Models.MicrosoftGraphManagedDevice]::FromJsonString(
            (ConvertTo-Json -InputObject $properties -Depth 3)
        )

        ($restored -is [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphManagedDevice]) | Should -BeTrue
        $restored.Id | Should -BeExactly $device.Id
        $restored.AzureAdDeviceId | Should -BeExactly $device.AzureAdDeviceId
        ($null -eq $restored.UserId) | Should -BeTrue
        $restored.EnrolledDateTime | Should -BeOfType [datetime]
        $restored.EnrolledDateTime.ToUniversalTime().ToString('o') | Should -BeExactly '2026-09-01T12:00:00.0000000Z'
        ([string] $restored.DeviceEnrollmentType) | Should -BeExactly 'unknown'
    }

    It 'rejects incompatible input before replacing an existing file' {
        $path = Join-Path $TestDrive 'unchanged.csv'
        Set-Content -LiteralPath $path -Value 'existing data'
        $device = & $factoryPath @common -DeviceName 'SYNTH-VALID'

        { @($device, [pscustomobject]@{ Id = 'invalid' }) | & $exportPath -Path $path } |
            Should -Throw '*Graph managed-device models*'
        (Get-Content -LiteralPath $path -Raw).Trim() | Should -BeExactly 'existing data'
    }
}
