BeforeAll {
    $reportModulePath = Join-Path $PSScriptRoot 'ParReports.psd1'
    $dataModulePath = Join-Path $PSScriptRoot '../ParData/ParData.psd1'
    $factoryPath = Join-Path $PSScriptRoot '../../tools/factories/New-FakeIntuneDevice.ps1'
    $existingFixtureVariable = Get-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name 'PAR_FixturePaths' -Scope Global -ErrorAction SilentlyContinue
    Remove-Module ParReports, ParData -ErrorAction SilentlyContinue
    Import-Module $reportModulePath -Force

    function New-TestCorrelationDevice {
        param(
            [string] $Id = 'INTUNE-001',
            [AllowNull()]
            [AllowEmptyString()]
            $SerialNumber = 'SYNTH-001'
        )

        [pscustomobject]@{
            Id = $Id
            SerialNumber = $SerialNumber
            DeviceName = 'SYNTH-DEVICE'
            AzureAdDeviceId = "ENTRA-$Id"
            UserId = 'SYNTH-USER'
            OperatingSystem = 'Android'
        }
    }

    function New-TestCorrelationAsset {
        param(
            [string] $AssetId = 'CMDB-001',
            [AllowNull()]
            [AllowEmptyString()]
            $SerialNumber = 'SYNTH-001'
        )

        [pscustomobject]@{
            assetId = $AssetId
            assetTag = 'SYNTH-TAG'
            deviceName = 'SYNTH-DIFFERENT-NAME'
            serialNumber = $SerialNumber
            assignedUserReference = 'CMDB-PERSON'
        }
    }

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

Describe 'Resolve-ParIntuneDeviceCmdbAsset' {
    It 'returns a unique candidate with the original source records and identifiers' {
        $device = New-TestCorrelationDevice -SerialNumber " synth-001 `t"
        $asset = New-TestCorrelationAsset -SerialNumber "`tSYNTH-001 "

        $rows = @(Resolve-ParIntuneDeviceCmdbAsset -InputObject $device -CmdbAsset $asset)

        $rows | Should -HaveCount 1
        $row = $rows[0]
        @($row.PSObject.Properties.Name) | Should -Be @(
            'IntuneDeviceId', 'IntuneDevice', 'SerialNumber', 'ComparisonSerialNumber',
            'Outcome', 'Reason', 'CandidateCount', 'CmdbCandidates'
        )
        $row.IntuneDeviceId | Should -BeExactly 'INTUNE-001'
        $row.IntuneDevice | Should -Be $device
        $row.IntuneDevice.AzureAdDeviceId | Should -BeExactly 'ENTRA-INTUNE-001'
        $row.SerialNumber | Should -BeExactly " synth-001 `t"
        $row.ComparisonSerialNumber | Should -BeExactly 'synth-001'
        $row.Outcome | Should -BeExactly 'Unique'
        $row.Reason | Should -BeExactly 'OneMatchingCmdbRecord'
        $row.CandidateCount | Should -Be 1
        ($row.CmdbCandidates -is [array]) | Should -BeTrue
        $row.CmdbCandidates | Should -HaveCount 1
        $row.CmdbCandidates[0] | Should -Be $asset
        $row.CmdbCandidates[0].assetId | Should -BeExactly 'CMDB-001'
        $row.CmdbCandidates[0].serialNumber | Should -BeExactly "`tSYNTH-001 "
    }

    It 'reports a missing candidate without falling back to matching names, tags, or identifiers' {
        $device = New-TestCorrelationDevice
        $asset = New-TestCorrelationAsset -AssetId $device.Id -SerialNumber 'OTHER'
        $asset.deviceName = $device.DeviceName
        $asset.assetTag = $device.SerialNumber
        $asset.assignedUserReference = $device.UserId

        $row = $device | Resolve-ParIntuneDeviceCmdbAsset -CmdbAsset $asset

        $row.Outcome | Should -BeExactly 'Missing'
        $row.Reason | Should -BeExactly 'NoMatchingSerialNumber'
        $row.CandidateCount | Should -Be 0
        ($row.CmdbCandidates -is [array]) | Should -BeTrue
        $row.CmdbCandidates | Should -HaveCount 0
    }

    It 'does not remove <Name> during comparison' -ForEach @(
        @{ Name = 'internal spaces'; SerialNumber = 'SYNTH 001' },
        @{ Name = 'punctuation'; SerialNumber = 'SYNTH-001' },
        @{ Name = 'leading zeroes'; SerialNumber = '001' }
    ) {
        $device = New-TestCorrelationDevice -SerialNumber $SerialNumber
        $asset = New-TestCorrelationAsset -SerialNumber ($SerialNumber -replace '[ -]|^0+', '')

        $row = $device | Resolve-ParIntuneDeviceCmdbAsset -CmdbAsset $asset

        $row.Outcome | Should -BeExactly 'Missing'
        $row.CandidateCount | Should -Be 0
    }

    It 'compares serials literally without wildcard or regular-expression matching' {
        $device = New-TestCorrelationDevice -SerialNumber 'SYNTH-*.[1]'
        $assets = @(
            (New-TestCorrelationAsset -AssetId 'OTHER' -SerialNumber 'SYNTH-ANY.1'),
            (New-TestCorrelationAsset -AssetId 'LITERAL' -SerialNumber 'SYNTH-*.[1]')
        )

        $row = $device | Resolve-ParIntuneDeviceCmdbAsset -CmdbAsset $assets

        $row.Outcome | Should -BeExactly 'Unique'
        $row.CmdbCandidates[0].assetId | Should -BeExactly 'LITERAL'
    }

    It 'retains every ambiguous candidate in source order without choosing a name or user match' {
        $device = New-TestCorrelationDevice
        $assets = @(
            (New-TestCorrelationAsset -AssetId 'CMDB-SECOND' -SerialNumber ' synth-001 '),
            (New-TestCorrelationAsset -AssetId 'UNRELATED' -SerialNumber 'OTHER'),
            (New-TestCorrelationAsset -AssetId 'CMDB-FIRST')
        )
        $assets[2].deviceName = $device.DeviceName
        $assets[2].assignedUserReference = $device.UserId

        $row = $device | Resolve-ParIntuneDeviceCmdbAsset -CmdbAsset $assets

        $row.Outcome | Should -BeExactly 'Ambiguous'
        $row.Reason | Should -BeExactly 'MultipleMatchingCmdbRecords'
        $row.CandidateCount | Should -Be 2
        ($row.CmdbCandidates -is [array]) | Should -BeTrue
        $row.CmdbCandidates.assetId | Should -Be @('CMDB-SECOND', 'CMDB-FIRST')
        $row.CmdbCandidates[0].serialNumber | Should -BeExactly ' synth-001 '
    }

    It 'keeps duplicate CMDB records and IDs explicitly ambiguous' {
        $asset = New-TestCorrelationAsset
        $assets = @($asset, (New-TestCorrelationAsset), $asset)

        $row = New-TestCorrelationDevice | Resolve-ParIntuneDeviceCmdbAsset -CmdbAsset $assets

        $row.Outcome | Should -BeExactly 'Ambiguous'
        $row.CandidateCount | Should -Be 3
        $row.CmdbCandidates.assetId | Should -Be @('CMDB-001', 'CMDB-001', 'CMDB-001')
    }

    It 'never matches a <Name> Intune serial to any CMDB serial' -ForEach @(
        @{ Name = 'null'; SerialNumber = $null },
        @{ Name = 'empty'; SerialNumber = '' },
        @{ Name = 'spaces'; SerialNumber = '   ' },
        @{ Name = 'mixed whitespace'; SerialNumber = " `t`r`n" }
    ) {
        $device = New-TestCorrelationDevice -SerialNumber $SerialNumber
        $assets = @(
            (New-TestCorrelationAsset -SerialNumber $null),
            (New-TestCorrelationAsset -SerialNumber ''),
            (New-TestCorrelationAsset -SerialNumber '   '),
            (New-TestCorrelationAsset -SerialNumber " `t`r`n"),
            (New-TestCorrelationAsset)
        )

        $row = $device | Resolve-ParIntuneDeviceCmdbAsset -CmdbAsset $assets

        $row.Outcome | Should -BeExactly 'Missing'
        $row.Reason | Should -BeExactly 'BlankSerialNumber'
        $row.ComparisonSerialNumber | Should -BeExactly ''
        $row.CandidateCount | Should -Be 0
        $row.CmdbCandidates | Should -HaveCount 0
        if ($null -eq $SerialNumber) {
            ($null -eq $row.SerialNumber) | Should -BeTrue
        }
        else {
            $row.SerialNumber | Should -BeExactly $SerialNumber
        }
    }

    It 'ignores blank CMDB serials and null elements for a nonblank Intune serial' {
        $assets = @(
            $null,
            (New-TestCorrelationAsset -SerialNumber $null),
            (New-TestCorrelationAsset -SerialNumber ''),
            (New-TestCorrelationAsset -SerialNumber " `t`r`n")
        )

        $row = New-TestCorrelationDevice | Resolve-ParIntuneDeviceCmdbAsset -CmdbAsset $assets

        $row.Outcome | Should -BeExactly 'Missing'
        $row.Reason | Should -BeExactly 'NoMatchingSerialNumber'
        $row.CandidateCount | Should -Be 0
    }

    It 'preserves repeated Intune serials and IDs with the same <Outcome> candidate evidence' -ForEach @(
        @{ Outcome = 'Unique'; CandidateCount = 1 },
        @{ Outcome = 'Ambiguous'; CandidateCount = 2 }
    ) {
        $first = New-TestCorrelationDevice -Id 'INTUNE-SECOND'
        $second = New-TestCorrelationDevice -Id 'INTUNE-FIRST' -SerialNumber ' synth-001 '
        $devices = @($first, $null, $second, $first)
        $assets = @(
            New-TestCorrelationAsset -AssetId 'CMDB-001'
            if ($CandidateCount -eq 2) {
                New-TestCorrelationAsset -AssetId 'CMDB-002'
            }
        )

        $arrayRows = @(Resolve-ParIntuneDeviceCmdbAsset -InputObject $devices -CmdbAsset $assets)
        $pipelineRows = @($devices | Resolve-ParIntuneDeviceCmdbAsset -CmdbAsset $assets)

        $arrayRows | Should -HaveCount 3
        $arrayRows.IntuneDeviceId | Should -Be @('INTUNE-SECOND', 'INTUNE-FIRST', 'INTUNE-SECOND')
        foreach ($row in $arrayRows) {
            $row.Outcome | Should -BeExactly $Outcome
            $row.CandidateCount | Should -Be $CandidateCount
            $row.CmdbCandidates.assetId | Should -Be @($assets.assetId)
        }
        ($pipelineRows | ConvertTo-Json -Depth 5) | Should -BeExactly ($arrayRows | ConvertTo-Json -Depth 5)
    }

    It 'returns no results for null devices, empty arrays, or an empty pipeline' {
        $assets = @(New-TestCorrelationAsset)

        @(Resolve-ParIntuneDeviceCmdbAsset -InputObject $null -CmdbAsset $assets) | Should -HaveCount 0
        @(Resolve-ParIntuneDeviceCmdbAsset -InputObject @() -CmdbAsset $assets) | Should -HaveCount 0
        @(Resolve-ParIntuneDeviceCmdbAsset -InputObject @($null, $null) -CmdbAsset $assets) | Should -HaveCount 0
        @(@() | Resolve-ParIntuneDeviceCmdbAsset -CmdbAsset $assets) | Should -HaveCount 0
    }

    It 'returns missing candidates for null or empty CMDB datasets' {
        $device = New-TestCorrelationDevice

        foreach ($assets in @($null, @(), @($null))) {
            $rows = @($device | Resolve-ParIntuneDeviceCmdbAsset -CmdbAsset $assets)

            $rows | Should -HaveCount 1
            $rows[0].Outcome | Should -BeExactly 'Missing'
            $rows[0].Reason | Should -BeExactly 'NoMatchingSerialNumber'
            $rows[0].CandidateCount | Should -Be 0
            ($rows[0].CmdbCandidates -is [array]) | Should -BeTrue
            $rows[0].CmdbCandidates | Should -HaveCount 0
        }
    }

    It 'leaves all supplied source properties unchanged across outcomes' {
        $devices = @(
            (New-TestCorrelationDevice -SerialNumber ' synth-001 '),
            (New-TestCorrelationDevice -SerialNumber $null),
            (New-TestCorrelationDevice -SerialNumber 'OTHER')
        )
        $assets = @((New-TestCorrelationAsset), (New-TestCorrelationAsset -AssetId 'CMDB-002'))
        $devicesBefore = $devices | ConvertTo-Json
        $assetsBefore = $assets | ConvertTo-Json

        $rows = @($devices | Resolve-ParIntuneDeviceCmdbAsset -CmdbAsset $assets)

        $rows.Outcome | Should -Be @('Ambiguous', 'Missing', 'Missing')
        ($devices | ConvertTo-Json) | Should -BeExactly $devicesBefore
        ($assets | ConvertTo-Json) | Should -BeExactly $assetsBefore
    }
}

Describe 'Device correlation with offline fixture retrieval' {
    It 'accepts restored Intune SDK models and retains unique, missing, and ambiguous fixture evidence' {
        $fixturePaths = @{
            IntuneDevice = Join-Path $PSScriptRoot '../../data/intune-devices.csv'
            CmdbAsset = Join-Path $PSScriptRoot '../../data/cmdb-assets.csv'
        }
        Import-Module $dataModulePath -ArgumentList $fixturePaths -Force
        try {
            $devices = @(Get-ParIntuneDevice)
            $assets = @(Get-ParCmdbAsset)

            $rows = @($devices | Resolve-ParIntuneDeviceCmdbAsset -CmdbAsset $assets)

            $rows | Should -HaveCount 3
            $rows.IntuneDeviceId | Should -Be @($devices.Id)
            $rows.Outcome | Should -Be @('Unique', 'Missing', 'Ambiguous')
            $rows.CandidateCount | Should -Be @(1, 0, 2)
            $rows[0].IntuneDevice | Should -BeOfType 'Microsoft.Graph.PowerShell.Models.MicrosoftGraphManagedDevice'
            $rows[0].CmdbCandidates[0].assetId | Should -BeExactly 'CMDB-ASSET-001'
            $rows[2].CmdbCandidates.assetId | Should -Be @('CMDB-ASSET-002', 'CMDB-ASSET-003')
        }
        finally {
            Remove-Module ParData -ErrorAction SilentlyContinue
        }
    }
}
