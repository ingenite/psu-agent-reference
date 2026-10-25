Describe 'Get-ParIntuneDevice' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot 'ParData.psd1'
        $existingFixtureVariable = Get-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue

        function New-TestDeviceRecord {
            [pscustomobject][ordered]@{
                id = '20000000-0000-4000-8000-000000000001'
                userId = '10000000-0000-4000-8000-000000000001'
                deviceName = 'SYNTH-TEST-001'
                enrolledDateTime = '2026-09-01T05:00:00.1234567-07:00'
                lastSyncDateTime = '2026-10-24T11:30:00-07:00'
                operatingSystem = 'Windows'
                osVersion = '10.0.26100.0'
                emailAddress = 'alex@example.invalid'
                azureADDeviceId = '30000000-0000-4000-8000-000000000001'
                userPrincipalName = 'alex@example.invalid'
                model = 'Synthetic Laptop'
                manufacturer = 'Fictional, "Devices"'
                serialNumber = 'SYNTH-000001'
                userDisplayName = "Example, Alex`nSynthetic User"
                deviceEnrollmentType = 'unknown'
            }
        }
    }

    BeforeEach {
        Remove-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
        $fixturePath = Join-Path $TestDrive 'devices.csv'
        $record = New-TestDeviceRecord
        $record | Export-Csv -LiteralPath $fixturePath -NoTypeInformation -Encoding utf8
        Remove-Module ParData -ErrorAction SilentlyContinue
        Import-Module $modulePath -ArgumentList @{ IntuneDevice = $fixturePath } -Force
    }

    AfterAll {
        Remove-Module ParData -ErrorAction SilentlyContinue
        if ($null -ne $existingFixtureVariable) {
            Set-Variable -Name 'PAR_FixturePaths' -Scope Global -Value $existingFixtureVariable.Value
        }
    }

    AfterEach {
        Remove-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
    }

    It 'restores all selected values as an SDK managed-device model, including quoted multiline fields' {
        $devices = @(Get-ParIntuneDevice)

        $devices | Should -HaveCount 1
        $device = $devices[0]
        ($device -is [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphManagedDevice]) | Should -BeTrue
        foreach ($propertyName in $record.PSObject.Properties.Name | Where-Object { $_ -notin @('enrolledDateTime', 'lastSyncDateTime') }) {
            ([string] $device.$propertyName) | Should -BeExactly $record.$propertyName
        }
        $device.EnrolledDateTime | Should -BeOfType [datetime]
        $device.LastSyncDateTime | Should -BeOfType [datetime]
        $device.EnrolledDateTime.ToUniversalTime().ToString('o') | Should -BeExactly '2026-09-01T12:00:00.1234567Z'
        $device.LastSyncDateTime.ToUniversalTime().ToString('o') | Should -BeExactly '2026-10-24T18:30:00.0000000Z'
        (Get-Module -All Microsoft.Graph.DeviceManagement | Select-Object -First 1).Version.ToString() | Should -BeExactly '2.41.2'
    }

    It 'uses the checked-in dataset by default, independently of the working directory' {
        Remove-Module ParData
        Push-Location $TestDrive
        try {
            Import-Module $modulePath -Force
            $devices = @(Get-ParIntuneDevice)
        }
        finally {
            Pop-Location
        }

        $devices | Should -HaveCount 3
        $devices[0].DeviceName | Should -BeExactly 'SYNTH-ASSIGNED-001'
        foreach ($device in $devices) {
            ($device -is [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphManagedDevice]) | Should -BeTrue
        }
        ($null -eq $devices[1].UserId) | Should -BeTrue
        ($null -eq $devices[2].UserId) | Should -BeTrue
    }

    It 'resolves a configured relative path at import and reads current contents on each call' {
        Remove-Module ParData
        Push-Location $TestDrive
        try {
            Import-Module $modulePath -ArgumentList @{ IntuneDevice = './devices.csv' } -Force
        }
        finally {
            Pop-Location
        }

        (Get-ParIntuneDevice).DeviceName | Should -BeExactly 'SYNTH-TEST-001'
        $record.deviceName = 'SYNTH-UPDATED'
        $record | Export-Csv -LiteralPath $fixturePath -NoTypeInformation
        (Get-ParIntuneDevice).DeviceName | Should -BeExactly 'SYNTH-UPDATED'
    }

    It 'uses the shared PSU fixture setting without explicit import arguments' {
        $global:PAR_FixturePaths = @{ IntuneDevice = $fixturePath }
        Remove-Module ParData
        Import-Module $modulePath -Force

        (Get-ParIntuneDevice).DeviceName | Should -BeExactly 'SYNTH-TEST-001'
    }

    It 'uses repository defaults for sources omitted from the shared setting' {
        $global:PAR_FixturePaths = @{}
        Remove-Module ParData
        Import-Module $modulePath -Force

        @(Get-ParIntuneDevice) | Should -HaveCount 3
    }

    It 'gives explicit import configuration precedence over the shared setting' {
        $global:PAR_FixturePaths = @{ IntuneDevice = (Join-Path $TestDrive 'unused.csv') }
        Remove-Module ParData
        Import-Module $modulePath -ArgumentList @{ IntuneDevice = $fixturePath } -Force

        (Get-ParIntuneDevice).DeviceName | Should -BeExactly 'SYNTH-TEST-001'
    }

    It 'accepts a shared hashtable restored through PowerShell serialization' {
        $serializedPath = Join-Path $TestDrive 'fixture-paths.xml'
        Export-Clixml -InputObject @{ IntuneDevice = $fixturePath } -LiteralPath $serializedPath
        $global:PAR_FixturePaths = Import-Clixml -LiteralPath $serializedPath
        Remove-Module ParData
        Import-Module $modulePath -Force

        (Get-ParIntuneDevice).DeviceName | Should -BeExactly 'SYNTH-TEST-001'
    }

    It 'rejects a <Name> shared configuration instead of using defaults' -ForEach @(
        @{ Name = 'null'; Value = $null },
        @{ Name = 'string'; Value = 'invalid' }
    ) {
        $global:PAR_FixturePaths = $Value
        Remove-Module ParData

        { Import-Module $modulePath -Force -ErrorAction Stop } |
            Should -Throw '*PAR_FixturePaths must be a hashtable*'
    }

    It 'rejects an unknown source in the shared setting' {
        $global:PAR_FixturePaths = @{ IntuenDevice = $fixturePath }
        Remove-Module ParData

        { Import-Module $modulePath -Force -ErrorAction Stop } |
            Should -Throw '*Unknown fixture source*IntuenDevice*'
    }

    It 'rejects an invalid path in the shared setting' {
        $global:PAR_FixturePaths = @{ IntuneDevice = '' }
        Remove-Module ParData

        { Import-Module $modulePath -Force -ErrorAction Stop } |
            Should -Throw '*Fixture path for*IntuneDevice*must be a nonblank string*'
    }

    It 'rejects an unknown fixture source instead of silently using the default' {
        Remove-Module ParData

        { Import-Module $modulePath -ArgumentList @{ IntuenDevice = $fixturePath } -Force -ErrorAction Stop } |
            Should -Throw '*Unknown fixture source*IntuenDevice*'
    }

    It 'rejects a <Name> configured fixture path' -ForEach @(
        @{ Name = 'blank'; Value = '   ' },
        @{ Name = 'null'; Value = $null },
        @{ Name = 'non-string'; Value = 42 }
    ) {
        Remove-Module ParData

        { Import-Module $modulePath -ArgumentList @{ IntuneDevice = $Value } -Force -ErrorAction Stop } |
            Should -Throw '*Fixture path for*IntuneDevice*must be a nonblank string*'
    }

    It 'fails retrieval if the source-specific SDK cannot be loaded' {
        Mock Import-Module -ModuleName ParData { throw 'Required SDK is unavailable.' } `
            -ParameterFilter { $Name -eq 'Microsoft.Graph.DeviceManagement' -and $RequiredVersion -eq '2.41.2' }

        { Get-ParIntuneDevice } | Should -Throw '*Required SDK is unavailable*'
        Should -Invoke Import-Module -ModuleName ParData -Exactly -Times 1 `
            -ParameterFilter { $Name -eq 'Microsoft.Graph.DeviceManagement' -and $RequiredVersion -eq '2.41.2' }
    }

    It 'normalizes empty user-association cells to actual null values' {
        foreach ($propertyName in @('userId', 'emailAddress', 'userPrincipalName', 'userDisplayName')) {
            $record.$propertyName = ''
        }
        $record | Export-Csv -LiteralPath $fixturePath -NoTypeInformation

        $device = Get-ParIntuneDevice

        foreach ($propertyName in @('UserId', 'EmailAddress', 'UserPrincipalName', 'UserDisplayName')) {
            ($null -eq $device.$propertyName) | Should -BeTrue
        }
    }

    It 'preserves whitespace user associations and empty hardware strings without interpreting them' {
        $record.userId = '   '
        $record.model = ''
        $record | Export-Csv -LiteralPath $fixturePath -NoTypeInformation

        $device = Get-ParIntuneDevice

        $device.UserId | Should -BeExactly '   '
        $device.Model | Should -BeExactly ''
    }

    It 'restores missing timestamps as null and omits an empty enrollment type' {
        $record.enrolledDateTime = ''
        $record.lastSyncDateTime = ''
        $record.deviceEnrollmentType = ''
        $record | Export-Csv -LiteralPath $fixturePath -NoTypeInformation

        $device = Get-ParIntuneDevice

        ($null -eq $device.EnrolledDateTime) | Should -BeTrue
        ($null -eq $device.LastSyncDateTime) | Should -BeTrue
        ([string] $device.DeviceEnrollmentType) | Should -BeNullOrEmpty
    }

    It 'retrieves records in fixture order without reporting filters or deduplication' {
        $second = New-TestDeviceRecord
        $second.operatingSystem = 'iOS'
        $second.deviceName = 'SYNTH-IOS'
        @($record, $second) | Export-Csv -LiteralPath $fixturePath -NoTypeInformation

        $devices = @(Get-ParIntuneDevice)

        $devices | Should -HaveCount 2
        $devices[0].DeviceName | Should -BeExactly 'SYNTH-TEST-001'
        $devices[1].DeviceName | Should -BeExactly 'SYNTH-IOS'
        $devices[1].OperatingSystem | Should -BeExactly 'iOS'
    }

    It 'returns no objects for a <Name> dataset' -ForEach @(
        @{ Name = 'zero-byte'; Content = '' },
        @{ Name = 'whitespace-only'; Content = " `r`n " }
    ) {
        Set-Content -LiteralPath $fixturePath -Value $Content -NoNewline

        @(Get-ParIntuneDevice) | Should -HaveCount 0
    }

    It 'validates a header-only dataset and returns no objects' {
        $header = ($record | ConvertTo-Csv -NoTypeInformation)[0]
        Set-Content -LiteralPath $fixturePath -Value $header

        @(Get-ParIntuneDevice) | Should -HaveCount 0
    }

    It 'accepts reordered columns and a final record without a trailing newline' {
        $columns = @($record.PSObject.Properties.Name | Sort-Object)
        $csv = $record | Select-Object -Property $columns | ConvertTo-Csv -NoTypeInformation
        Set-Content -LiteralPath $fixturePath -Value ($csv -join "`n") -NoNewline

        (Get-ParIntuneDevice).DeviceName | Should -BeExactly 'SYNTH-TEST-001'
    }

    It 'terminates with path context when the fixture is missing' {
        Remove-Item -LiteralPath $fixturePath

        { Get-ParIntuneDevice } | Should -Throw '*Cannot read Intune device fixture*devices.csv*'
        Test-Path -LiteralPath $fixturePath | Should -BeFalse
    }

    It 'rejects an incompatible header even without data records' {
        $header = ($record | ConvertTo-Csv -NoTypeInformation)[0] -replace 'deviceName', 'unexpected'
        Set-Content -LiteralPath $fixturePath -Value $header

        { Get-ParIntuneDevice } | Should -Throw '*Incompatible Intune device fixture*'
    }

    It 'rejects duplicate header names instead of dropping a property' {
        $header = ($record | ConvertTo-Csv -NoTypeInformation)[0] -replace 'deviceName', 'id'
        Set-Content -LiteralPath $fixturePath -Value $header

        { Get-ParIntuneDevice } | Should -Throw '*Incompatible Intune device fixture*'
    }

    It 'rejects CSV with <Name>' -ForEach @(
        @{ Name = 'surplus cells'; Suffix = ',extra' },
        @{ Name = 'an unterminated quote'; Suffix = ',"broken' }
    ) {
        $csv = @($record | ConvertTo-Csv -NoTypeInformation)
        Set-Content -LiteralPath $fixturePath -Value @($csv[0], ($csv[1] + $Suffix))

        { Get-ParIntuneDevice } | Should -Throw '*expected CSV records with 15 cells and balanced quotes*'
    }

    It 'rejects truncated data records' {
        $csv = @($record | ConvertTo-Csv -NoTypeInformation)
        Set-Content -LiteralPath $fixturePath -Value @($csv[0], '"only-one-cell"')

        { Get-ParIntuneDevice } | Should -Throw '*expected CSV records with 15 cells and balanced quotes*'
    }

    It 'rejects a blank <PropertyName>' -ForEach @(
        @{ PropertyName = 'id' },
        @{ PropertyName = 'deviceName' }
    ) {
        $record.$PropertyName = '   '
        $record | Export-Csv -LiteralPath $fixturePath -NoTypeInformation

        { Get-ParIntuneDevice } | Should -Throw "*data record 1*${PropertyName} must not be blank*"
    }

    It 'rejects a <Name> timestamp with record context' -ForEach @(
        @{ Name = 'non-date'; PropertyName = 'enrolledDateTime'; Value = 'not-a-date' },
        @{ Name = 'zone-less'; PropertyName = 'lastSyncDateTime'; Value = '2026-10-24T18:30:00' },
        @{ Name = 'calendar-invalid'; PropertyName = 'enrolledDateTime'; Value = '2026-02-30T12:00:00Z' }
    ) {
        $record.$PropertyName = $Value
        $record | Export-Csv -LiteralPath $fixturePath -NoTypeInformation

        { Get-ParIntuneDevice } | Should -Throw '*Invalid Intune device fixture*devices.csv*data record 1*'
    }

    It 'emits no partial results when a later record is invalid' {
        $second = New-TestDeviceRecord
        $second.lastSyncDateTime = 'invalid'
        @($record, $second) | Export-Csv -LiteralPath $fixturePath -NoTypeInformation
        $received = @()
        $failure = $null

        try {
            Get-ParIntuneDevice | ForEach-Object { $received += $_ }
        }
        catch {
            $failure = $_
        }

        $failure | Should -Not -BeNullOrEmpty
        $failure.Exception.Message | Should -BeLike '*data record 2*'
        $received | Should -HaveCount 0
    }

    It 'retrieves the existing factory and exporter output without invoking them at retrieval time' {
        $factoryPath = Join-Path $PSScriptRoot '../../tools/factories/New-FakeIntuneDevice.ps1'
        $exportPath = Join-Path $PSScriptRoot '../../tools/factories/Export-FakeIntuneDevice.ps1'
        $source = & $factoryPath -DeviceName 'SYNTH-ROUNDTRIP' -UserId $null `
            -EnrolledDateTime '2026-09-01T12:00:00Z' -LastSyncDateTime '2026-10-24T18:30:00Z'
        $source | & $exportPath -Path $fixturePath

        $device = Get-ParIntuneDevice

        $device.Id | Should -BeExactly $source.Id
        $device.AzureAdDeviceId | Should -BeExactly $source.AzureAdDeviceId
        $device.DeviceName | Should -BeExactly 'SYNTH-ROUNDTRIP'
        ($null -eq $device.UserId) | Should -BeTrue
        $device.EnrolledDateTime | Should -Be $source.EnrolledDateTime
        $device.LastSyncDateTime | Should -Be $source.LastSyncDateTime
    }
}
