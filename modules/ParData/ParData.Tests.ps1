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

    It 'preserves unquoted Intune strings and restores empty association cells without trimming' {
        $record.id = ' opaque-intune-id '
        $record.userId = '   '
        $record.userPrincipalName = ''
        $record.model = ''
        $record.manufacturer = 'Maker'
        $record.userDisplayName = '  Alex Example  '
        Set-Content -LiteralPath $fixturePath -Value @(
            ($record.PSObject.Properties.Name -join ',')
            ($record.PSObject.Properties.Value -join ',')
        )

        $device = Get-ParIntuneDevice

        $device.Id | Should -BeExactly ' opaque-intune-id '
        $device.UserId | Should -BeExactly '   '
        $device.UserDisplayName | Should -BeExactly '  Alex Example  '
        $device.Model | Should -BeExactly ''
        ($null -eq $device.UserPrincipalName) | Should -BeTrue
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

Describe '<Command> fixture retrieval' -ForEach @(
    @{
        SourceName = 'EntraUser'; Command = 'Get-ParEntraUser'; SourceDescription = 'Entra user'
        IdProperty = 'id'; OptionalProperties = @('userPrincipalName', 'mail')
        FixtureValues = [ordered]@{
            id = ' opaque-user-A '; displayName = "Example, `"Alex`"`r`nCafé"
            userPrincipalName = ' signin@example.invalid '; mail = '   '; accountEnabled = 'False'
        }
    },
    @{
        SourceName = 'CmdbAsset'; Command = 'Get-ParCmdbAsset'; SourceDescription = 'CMDB asset'
        IdProperty = 'assetId'; OptionalProperties = @('assetTag', 'deviceName', 'serialNumber', 'assignedUserReference')
        FixtureValues = [ordered]@{
            assetId = ' opaque-asset-A '; assetTag = "Inventory, `"Test`"`r`nCafé"
            deviceName = ' SYNTH-TEST '; serialNumber = '   '; assignedUserReference = ' CMDB-PERSON-A '
        }
    }
) {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot 'ParData.psd1'
        $existingFixtureVariable = Get-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
        function New-TestSourceRecord {
            $properties = [ordered]@{}
            foreach ($key in $FixtureValues.Keys) { $properties[$key] = $FixtureValues[$key] }
            [pscustomobject] $properties
        }
    }

    BeforeEach {
        Remove-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
        $fixturePath = Join-Path $TestDrive 'source[1].csv'
        $record = New-TestSourceRecord
        $columns = @($record.PSObject.Properties.Name)
        $record | Export-Csv -LiteralPath $fixturePath -NoTypeInformation -Encoding utf8
        Remove-Module ParData -ErrorAction SilentlyContinue
        Import-Module $modulePath -ArgumentList @{ $SourceName = $fixturePath } -Force
    }

    AfterEach {
        Remove-Module ParData -ErrorAction SilentlyContinue
        Remove-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
    }

    AfterAll {
        if ($null -ne $existingFixtureVariable) {
            Set-Variable -Name 'PAR_FixturePaths' -Scope Global -Value $existingFixtureVariable.Value
        }
    }

    It 'preserves quoted commas, doubled quotes, multiline UTF-8, opaque IDs, and whitespace' {
        $records = @(& $Command)

        $records | Should -HaveCount 1
        foreach ($column in $columns | Where-Object { $_ -ne 'accountEnabled' }) {
            $records[0].$column | Should -BeExactly $record.$column
        }
    }

    It 'restores empty optional cells as actual null without inferring other values' {
        foreach ($property in $OptionalProperties) { $record.$property = '' }
        $record | Export-Csv -LiteralPath $fixturePath -NoTypeInformation

        $restored = & $Command

        foreach ($property in $OptionalProperties) { ($null -eq $restored.$property) | Should -BeTrue }
    }

    It 'preserves unquoted nonempty strings, including leading and trailing whitespace' {
        $values = if ($SourceName -eq 'EntraUser') {
            ' user-id , User Name ,   , mail@example.invalid ,False'
        } else {
            ' asset-id ,   , device , serial , person '
        }
        Set-Content -LiteralPath $fixturePath -Value @(($columns -join ','), $values)

        $restored = & $Command
        $expected = $values -split ','

        for ($index = 0; $index -lt 4; $index++) {
            $restored.($columns[$index]) | Should -BeExactly $expected[$index]
        }
        if ($SourceName -eq 'CmdbAsset') { $restored.assignedUserReference | Should -BeExactly ' person ' }
    }

    It 'preserves order and duplicates without filtering or deduplication' {
        $second = New-TestSourceRecord
        $second.$IdProperty = 'another-opaque-id'
        @($second, $record, $second) | Export-Csv -LiteralPath $fixturePath -NoTypeInformation

        $records = @(& $Command)

        $records | Should -HaveCount 3
        ($records.$IdProperty -join '|') | Should -BeExactly "another-opaque-id|$($record.$IdProperty)|another-opaque-id"
    }

    It 'uses repository defaults independently of the working directory for omitted sources' {
        Remove-Module ParData
        $global:PAR_FixturePaths = @{ IntuneDevice = (Join-Path $TestDrive 'unused.csv') }
        Push-Location $TestDrive
        try {
            Import-Module $modulePath -Force
            $records = @(& $Command)
        }
        finally { Pop-Location }

        $records | Should -HaveCount 3
        $expectedId = if ($SourceName -eq 'EntraUser') { '10000000-0000-4000-8000-000000000001' } else { 'CMDB-ASSET-001' }
        $records[0].$IdProperty | Should -BeExactly $expectedId
    }

    It 'uses shared configuration and explicit per-source overrides while retaining other sources' {
        $sharedPath = Join-Path $TestDrive 'shared.csv'
        $shared = New-TestSourceRecord
        $shared.$IdProperty = 'shared-id'
        $shared | Export-Csv -LiteralPath $sharedPath -NoTypeInformation
        $global:PAR_FixturePaths = @{ $SourceName = $sharedPath }
        Remove-Module ParData
        Import-Module $modulePath -Force
        (& $Command).$IdProperty | Should -BeExactly 'shared-id'

        Remove-Module ParData
        Import-Module $modulePath -ArgumentList @{ $SourceName = $fixturePath } -Force
        (& $Command).$IdProperty | Should -BeExactly $record.$IdProperty
        @(Get-ParIntuneDevice) | Should -HaveCount 3
        $otherCommand = if ($SourceName -eq 'EntraUser') { 'Get-ParCmdbAsset' } else { 'Get-ParEntraUser' }
        @(& $otherCommand) | Should -HaveCount 3
    }

    It 'anchors relative paths at import, captures configuration, and rereads current file contents' {
        Remove-Module ParData
        $configuredPaths = @{ $SourceName = './source[1].csv' }
        $global:PAR_FixturePaths = $configuredPaths
        Push-Location $TestDrive
        try { Import-Module $modulePath -Force }
        finally { Pop-Location }
        $configuredPaths[$SourceName] = 'unused.csv'
        (& $Command).$IdProperty | Should -BeExactly $record.$IdProperty

        $record.$IdProperty = 'updated-id'
        $record | Export-Csv -LiteralPath $fixturePath -NoTypeInformation
        (& $Command).$IdProperty | Should -BeExactly 'updated-id'
    }

    It 'rejects invalid configured paths in either configuration layer' {
        foreach ($value in @($null, '', '   ', 42)) {
            Remove-Module ParData -ErrorAction SilentlyContinue
            $global:PAR_FixturePaths = @{ $SourceName = $value }
            { Import-Module $modulePath -Force -ErrorAction Stop } | Should -Throw '*must be a nonblank string*'
            Remove-Variable -Name 'PAR_FixturePaths' -Scope Global
            { Import-Module $modulePath -ArgumentList @{ $SourceName = $value } -Force -ErrorAction Stop } |
                Should -Throw '*must be a nonblank string*'
        }
    }

    It 'returns no objects for zero-byte, whitespace-only, or valid header-only files' {
        foreach ($content in @('', " `r`n ", ($columns -join ','))) {
            Set-Content -LiteralPath $fixturePath -Value $content -NoNewline
            @(& $Command) | Should -HaveCount 0
        }
    }

    It 'accepts reordered headers, LF or CRLF, and an optional final newline' {
        foreach ($separator in @("`n", "`r`n")) {
            foreach ($finalNewline in @('', $separator)) {
                $csv = $record | Select-Object -Property ($columns | Sort-Object) | ConvertTo-Csv -NoTypeInformation
                Set-Content -LiteralPath $fixturePath -Value (($csv -join $separator) + $finalNewline) -NoNewline
                (& $Command).$IdProperty | Should -BeExactly $record.$IdProperty
            }
        }
    }

    It 'rejects incompatible, duplicate, wrong-case, missing, extra, and blank header names even without records' {
        $invalidHeaders = @(
            ($columns -join ',') -creplace $columns[0], 'unexpected'
            ($columns -join ',') -creplace $columns[0], $columns[1]
            ($columns -join ',') -creplace $columns[0], $columns[0].ToUpper()
            ($columns[1..4] -join ',')
            ($columns -join ',') + ',extra'
            ($columns -join ',') -creplace $columns[0], ''
        )
        foreach ($header in $invalidHeaders) {
            Set-Content -LiteralPath $fixturePath -Value $header
            { & $Command } | Should -Throw "*${SourceDescription} fixture*source``[1``].csv*"
        }
    }

    It 'rejects malformed records before emitting any output' {
        $header = $columns -join ','
        foreach ($badRecord in @('a,b,c,d,e,f', 'a,b', '"unterminated,b,c,d,e', 'a"b,c,d,e,f', '"a"extra,b,c,d,e', '')) {
            $csv = @($record | ConvertTo-Csv -NoTypeInformation)
            Set-Content -LiteralPath $fixturePath -Value @($header, $csv[1], $badRecord)
            $received = @()
            $failure = $null
            try { & $Command | ForEach-Object { $received += $_ } }
            catch { $failure = $_ }

            $failure.Exception.Message | Should -BeLike '*expected CSV records with 5 cells and balanced quotes*'
            $received | Should -HaveCount 0
        }
    }

    It 'rejects empty and whitespace-only required IDs with record context and no partial output' {
        foreach ($value in @('', '   ')) {
            $second = New-TestSourceRecord
            $second.$IdProperty = $value
            @($record, $second) | Export-Csv -LiteralPath $fixturePath -NoTypeInformation
            $received = @()
            $failure = $null
            try { & $Command | ForEach-Object { $received += $_ } }
            catch { $failure = $_ }

            $failure.Exception.Message | Should -BeLike "*data record 2*${IdProperty} must not be blank*"
            $failure.Exception.Message.Contains($fixturePath) | Should -BeTrue
            $received | Should -HaveCount 0
        }
    }

    It 'reports missing and unreadable paths without creating files' {
        Remove-Item -LiteralPath $fixturePath
        { & $Command } | Should -Throw "*Cannot read ${SourceDescription} fixture*"
        Test-Path -LiteralPath $fixturePath | Should -BeFalse
        New-Item -Path $fixturePath -ItemType Directory | Out-Null
        { & $Command } | Should -Throw "*Cannot read ${SourceDescription} fixture*"
    }
}

Describe 'ParData source dependencies and exports' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot 'ParData.psd1'
        $existingFixtureVariable = Get-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
    }

    AfterEach {
        Remove-Module ParData -ErrorAction SilentlyContinue
        Remove-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
        if ($null -ne $existingFixtureVariable) {
            Set-Variable -Name 'PAR_FixturePaths' -Scope Global -Value $existingFixtureVariable.Value
        }
    }

    It 'combines an explicit CMDB path, a shared Entra path, and the default Intune path' {
        $userPath = Join-Path $TestDrive 'shared-users.csv'
        $assetPath = Join-Path $TestDrive 'explicit-assets.csv'
        [pscustomobject][ordered]@{
            id = 'shared-user'; displayName = 'Shared User'; userPrincipalName = ''; mail = ''; accountEnabled = ''
        } | Export-Csv -LiteralPath $userPath -NoTypeInformation
        [pscustomobject][ordered]@{
            assetId = 'explicit-asset'; assetTag = ''; deviceName = ''; serialNumber = ''; assignedUserReference = ''
        } | Export-Csv -LiteralPath $assetPath -NoTypeInformation
        $global:PAR_FixturePaths = @{ EntraUser = $userPath; CmdbAsset = (Join-Path $TestDrive 'unused.csv') }
        Remove-Module ParData -ErrorAction SilentlyContinue
        Import-Module $modulePath -ArgumentList @{ CmdbAsset = $assetPath } -Force

        (Get-ParEntraUser).Id | Should -BeExactly 'shared-user'
        (Get-ParCmdbAsset).assetId | Should -BeExactly 'explicit-asset'
        @(Get-ParIntuneDevice) | Should -HaveCount 3
    }

    It 'imports and retrieves CMDB without Graph, then loads only the Users source SDK for Entra' {
        $scriptPath = Join-Path $TestDrive 'dependencies.ps1'
        @'
param([string] $ModulePath)
$ErrorActionPreference = 'Stop'
Import-Module $ModulePath
$afterImport = @(Get-Module -All Microsoft.Graph.*).Count
$assets = @(Get-ParCmdbAsset)
$afterCmdb = @(Get-Module -All Microsoft.Graph.*).Count
$users = @(Get-ParEntraUser)
[pscustomobject]@{
    AfterImport = $afterImport
    AfterCmdb = $afterCmdb
    AssetCount = $assets.Count
    UserCount = $users.Count
    UsersVersion = (Get-Module -All Microsoft.Graph.Users | Select-Object -First 1).Version.ToString()
    DeviceSdkCount = @(Get-Module -All Microsoft.Graph.DeviceManagement).Count
    Exports = @((Get-Module ParData).ExportedFunctions.Keys | Sort-Object)
} | ConvertTo-Json -Compress
'@ | Set-Content -LiteralPath $scriptPath
        $result = & 'C:/Program Files/PowerShell/7/pwsh.exe' -NoProfile -File $scriptPath $modulePath | ConvertFrom-Json

        $LASTEXITCODE | Should -Be 0
        $result.AfterImport | Should -Be 0
        $result.AfterCmdb | Should -Be 0
        $result.AssetCount | Should -Be 3
        $result.UserCount | Should -Be 3
        $result.UsersVersion | Should -BeExactly '2.41.2'
        $result.DeviceSdkCount | Should -Be 0
        ($result.Exports -join ',') | Should -BeExactly 'Get-ParCmdbAsset,Get-ParEntraUser,Get-ParIntuneDevice'
    }
}

Describe 'Get-ParEntraUser model restoration' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot 'ParData.psd1'
        $factoryPath = Join-Path $PSScriptRoot '../../tools/factories/New-FakeEntraUser.ps1'
        $exportPath = Join-Path $PSScriptRoot '../../tools/factories/Export-FakeEntraUser.ps1'
        $existingFixtureVariable = Get-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeEach {
        Remove-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
        $fixturePath = Join-Path $TestDrive 'users.csv'
        $record = [pscustomobject][ordered]@{
            id = 'synthetic-user'; displayName = "Example`nAlex"
            userPrincipalName = ''; mail = ''; accountEnabled = 'False'
        }
        $record | Export-Csv -LiteralPath $fixturePath -NoTypeInformation
        Remove-Module ParData -ErrorAction SilentlyContinue
        Import-Module $modulePath -ArgumentList @{ EntraUser = $fixturePath } -Force
    }

    AfterEach { Remove-Module ParData -ErrorAction SilentlyContinue }

    AfterAll {
        if ($null -ne $existingFixtureVariable) {
            Set-Variable -Name 'PAR_FixturePaths' -Scope Global -Value $existingFixtureVariable.Value
        }
    }

    It 'restores <Text> as Boolean <Expected>' -ForEach @(
        @{ Text = 'True'; Expected = $true },
        @{ Text = 'False'; Expected = $false },
        @{ Text = 'TRUE'; Expected = $true },
        @{ Text = 'false'; Expected = $false },
        @{ Text = 'fAlSe'; Expected = $false }
    ) {
        $record.accountEnabled = $Text
        $record | Export-Csv -LiteralPath $fixturePath -NoTypeInformation
        $user = Get-ParEntraUser

        ($user -is [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser]) | Should -BeTrue
        $user.AccountEnabled | Should -BeOfType [bool]
        $user.AccountEnabled | Should -Be $Expected
        ($null -eq $user.Mail) | Should -BeTrue
    }

    It 'distinguishes false from actual null with quoted or unquoted empty cells' {
        $header = ($record | ConvertTo-Csv -NoTypeInformation)[0]
        Set-Content -LiteralPath $fixturePath -Value @($header, 'one,One,,,False', 'two,Two,,,', 'three,Three,"","",""')
        $users = @(Get-ParEntraUser)

        $users | Should -HaveCount 3
        $users[0].AccountEnabled | Should -BeFalse
        foreach ($index in 1..2) {
            ($null -eq $users[$index].AccountEnabled) | Should -BeTrue
            ($null -eq $users[$index].Mail) | Should -BeTrue
            ($null -eq $users[$index].UserPrincipalName) | Should -BeTrue
        }
    }

    It 'rejects invalid Boolean text without partial output or whitespace coercion' {
        foreach ($text in @('0', '1', 'yes', '$false', 'null', '   ', ' False', 'False ', 'falsehood')) {
            $second = $record | Select-Object *
            $second.accountEnabled = $text
            @($record, $second) | Export-Csv -LiteralPath $fixturePath -NoTypeInformation
            $received = @()
            $failure = $null
            try { Get-ParEntraUser | ForEach-Object { $received += $_ } }
            catch { $failure = $_ }

            $failure.Exception.Message | Should -BeLike '*users.csv*data record 2*accountEnabled must be True or False*'
            $received | Should -HaveCount 0
        }
    }

    It 'rejects empty or whitespace display names' {
        foreach ($value in @('', '   ')) {
            $record.displayName = $value
            $record | Export-Csv -LiteralPath $fixturePath -NoTypeInformation
            { Get-ParEntraUser } | Should -Throw '*data record 1*displayName must not be blank*'
        }
    }

    It 'fails retrieval when the exact Users SDK cannot load' {
        Mock Import-Module -ModuleName ParData { throw 'Required Users SDK unavailable.' } `
            -ParameterFilter { $Name -eq 'Microsoft.Graph.Users' -and $RequiredVersion -eq '2.41.2' }

        { Get-ParEntraUser } | Should -Throw '*Required Users SDK unavailable*'
        Should -Invoke Import-Module -ModuleName ParData -Exactly -Times 1 `
            -ParameterFilter { $Name -eq 'Microsoft.Graph.Users' -and $RequiredVersion -eq '2.41.2' }
    }

    It 'round-trips factory and exporter values through temporary files including null, empty, true, and false' {
        $sources = @(
            & $factoryPath -Id ' user-A ' -DisplayName "Example, `"Alex`"`nCafé" -UserPrincipalName ' sign-in ' -Mail ' ' -AccountEnabled $true
            & $factoryPath -Id 'user-B' -DisplayName 'Blair' -UserPrincipalName '' -AccountEnabled $false
            & $factoryPath -Id 'user-C' -DisplayName 'Casey'
        )
        @($sources[1], $sources[0], $sources[2], $sources[1]) | & $exportPath -Path $fixturePath
        $users = @(Get-ParEntraUser)

        $users | Should -HaveCount 4
        $expectedSources = @($sources[1], $sources[0], $sources[2], $sources[1])
        for ($index = 0; $index -lt $users.Count; $index++) {
            ($users[$index] -is [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser]) | Should -BeTrue
            foreach ($property in @('Id', 'DisplayName', 'UserPrincipalName', 'Mail', 'AccountEnabled')) {
                $expected = $expectedSources[$index].$property
                if ($null -eq $expected -or ($expected -is [string] -and $expected -ceq '')) {
                    ($null -eq $users[$index].$property) | Should -BeTrue
                } elseif ($expected -is [string]) {
                    $users[$index].$property | Should -BeExactly $expected
                } else {
                    $users[$index].$property | Should -Be $expected
                }
            }
        }
    }
}

Describe 'Get-ParCmdbAsset source restoration' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot 'ParData.psd1'
        $factoryPath = Join-Path $PSScriptRoot '../../tools/factories/New-FakeCmdbAsset.ps1'
        $exportPath = Join-Path $PSScriptRoot '../../tools/factories/Export-FakeCmdbAsset.ps1'
        $existingFixtureVariable = Get-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
    }

    BeforeEach {
        Remove-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
        $fixturePath = Join-Path $TestDrive 'assets.csv'
        Remove-Module ParData -ErrorAction SilentlyContinue
        Import-Module $modulePath -ArgumentList @{ CmdbAsset = $fixturePath } -Force
    }

    AfterEach { Remove-Module ParData -ErrorAction SilentlyContinue }

    AfterAll {
        if ($null -ne $existingFixtureVariable) {
            Set-Variable -Name 'PAR_FixturePaths' -Scope Global -Value $existingFixtureVariable.Value
        }
    }

    It 'round-trips plain factory objects through temporary CSV without mapping opaque person references' {
        $sources = @(
            & $factoryPath -AssetId ' CMDB-A ' -AssetTag "Label, `"Test`"`nCafé" -DeviceName ' Host ' -SerialNumber ' ' -AssignedUserReference 'CMDB-PERSON-A'
            & $factoryPath -AssetId 'CMDB-B' -AssetTag '' -DeviceName $null -SerialNumber ''
        )
        @($sources[1], $sources[0], $sources[1]) | & $exportPath -Path $fixturePath
        $assets = @(Get-ParCmdbAsset)

        $assets | Should -HaveCount 3
        $expectedSources = @($sources[1], $sources[0], $sources[1])
        for ($index = 0; $index -lt $assets.Count; $index++) {
            $assets[$index] | Should -BeOfType [pscustomobject]
            ($assets[$index].PSObject.Properties.Name -join ',') |
                Should -BeExactly 'assetId,assetTag,deviceName,serialNumber,assignedUserReference'
            foreach ($property in $expectedSources[$index].PSObject.Properties.Name) {
                $expected = $expectedSources[$index].$property
                if ($null -eq $expected -or $expected -ceq '') {
                    ($null -eq $assets[$index].$property) | Should -BeTrue
                } else {
                    $assets[$index].$property | Should -BeOfType [string]
                    $assets[$index].$property | Should -BeExactly $expected
                }
            }
        }
    }

    It 'normalizes quoted and unquoted empty optional cells to null' {
        Set-Content -LiteralPath $fixturePath -Value @(
            'assetId,assetTag,deviceName,serialNumber,assignedUserReference'
            'one,,,,'
            'two,"","","",""'
        )
        $assets = @(Get-ParCmdbAsset)

        $assets | Should -HaveCount 2
        foreach ($asset in $assets) {
            foreach ($property in @('assetTag', 'deviceName', 'serialNumber', 'assignedUserReference')) {
                ($null -eq $asset.$property) | Should -BeTrue
            }
        }
    }
}
