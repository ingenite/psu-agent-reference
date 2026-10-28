Describe 'Export-FakeCmdbAsset' {
    BeforeAll {
        $factoryPath = Join-Path $PSScriptRoot 'New-FakeCmdbAsset.ps1'
        $exportPath = Join-Path $PSScriptRoot 'Export-FakeCmdbAsset.ps1'
        $columns = 'assetId,assetTag,deviceName,serialNumber,assignedUserReference'
    }

    It 'exports fixed columns and round-trips punctuation, Unicode, multiline text, and opaque references' {
        $path = Join-Path $TestDrive 'nested/assets.csv'
        $parameters = @{
            AssetId = 'CMDB-ASSET-001'
            AssetTag = 'PAR, "001"'
            DeviceName = "SYNTH-Café`nLaptop"
            SerialNumber = '0000123'
            AssignedUserReference = 'CMDB-PERSON-001'
        }
        $asset = & $factoryPath @parameters
        $asset | Add-Member -NotePropertyName 'Extra' -NotePropertyValue 'ignored'
        $before = $asset | ConvertTo-Json

        $output = @($asset | & $exportPath -Path $path)
        $rows = @(Import-Csv -LiteralPath $path -Encoding utf8)

        $output | Should -HaveCount 0
        $rows | Should -HaveCount 1
        ($rows[0].PSObject.Properties.Name -join ',') | Should -BeExactly $columns
        foreach ($column in $rows[0].PSObject.Properties.Name) {
            $rows[0].$column | Should -BeExactly $asset.$column
        }
        ($asset | ConvertTo-Json) | Should -BeExactly $before
    }

    It 'accepts an array, retains order and duplicates, and replaces previous data' {
        $path = Join-Path $TestDrive 'replace.csv'
        & $factoryPath -AssetId 'CMDB-OLD' | & $exportPath -Path $path
        $assets = @(
            & $factoryPath -AssetId 'CMDB-SECOND' -DeviceName 'SYNTH-SHARED'
            & $factoryPath -AssetId 'CMDB-FIRST' -DeviceName 'SYNTH-SHARED'
            & $factoryPath -AssetId 'CMDB-SECOND' -DeviceName 'SYNTH-SHARED'
        )

        & $exportPath -InputObject $assets -Path $path
        $rows = @(Import-Csv -LiteralPath $path)

        $rows | Should -HaveCount 3
        ($rows.assetId -join ',') | Should -BeExactly 'CMDB-SECOND,CMDB-FIRST,CMDB-SECOND'
    }

    It 'appends an array while retaining existing rows, duplicate IDs, and one header' {
        $path = Join-Path $TestDrive 'append.csv'
        & $factoryPath -AssetId 'CMDB-FIRST' -AssignedUserReference 'CMDB-PERSON-001' |
            & $exportPath -Path $path
        $assets = @(
            & $factoryPath -AssetId 'CMDB-SECOND'
            & $factoryPath -AssetId 'CMDB-FIRST'
        )

        $output = @(& $exportPath -InputObject $assets -Path $path -Append)
        $rows = @(Import-Csv -LiteralPath $path)

        $output | Should -HaveCount 0
        $rows | Should -HaveCount 3
        ($rows.assetId -join ',') | Should -BeExactly 'CMDB-FIRST,CMDB-SECOND,CMDB-FIRST'
        $rows[0].assignedUserReference | Should -BeExactly 'CMDB-PERSON-001'
        $rows[1].assignedUserReference | Should -BeExactly ''
        ($rows[0].PSObject.Properties.Name -join ',') | Should -BeExactly $columns
        @(Get-Content -LiteralPath $path) | Should -HaveCount 4
    }

    It 'creates a missing CSV and parent directory when appending' {
        $path = Join-Path $TestDrive 'append-new/assets.csv'

        & $factoryPath -AssetId 'CMDB-NEW' | & $exportPath -Path $path -Append
        $rows = @(Import-Csv -LiteralPath $path)

        $rows | Should -HaveCount 1
        $rows[0].assetId | Should -BeExactly 'CMDB-NEW'
        ($rows[0].PSObject.Properties.Name -join ',') | Should -BeExactly $columns
    }

    It 'rejects append to an incompatible header without changing the file' {
        $path = Join-Path $TestDrive 'incompatible.csv'
        Set-Content -LiteralPath $path -Value @('unexpected', 'existing data')
        $before = Get-Content -LiteralPath $path -Raw

        { & $factoryPath -AssetId 'CMDB-NEW' | & $exportPath -Path $path -Append } |
            Should -Throw
        (Get-Content -LiteralPath $path -Raw) | Should -BeExactly $before
    }

    It 'rejects a later invalid record before appending any rows' {
        $path = Join-Path $TestDrive 'append-invalid.csv'
        & $factoryPath -AssetId 'CMDB-EXISTING' | & $exportPath -Path $path
        $before = Get-Content -LiteralPath $path -Raw
        $valid = & $factoryPath -AssetId 'CMDB-NEW'
        $invalid = [pscustomobject]@{ assetId = 'CMDB-INCOMPLETE' }

        { @($valid, $invalid) | & $exportPath -Path $path -Append } | Should -Throw
        (Get-Content -LiteralPath $path -Raw) | Should -BeExactly $before
    }

    It 'represents null and empty values as empty CSV cells while retaining whitespace' {
        $path = Join-Path $TestDrive 'optional.csv'
        @(
            & $factoryPath -AssetId 'CMDB-NULL'
            foreach ($value in @('', ' ')) {
                $parameters = @{
                    AssetId = if ($value -eq '') { 'CMDB-EMPTY' } else { 'CMDB-SPACE' }
                    AssetTag = $value
                    DeviceName = $value
                    SerialNumber = $value
                    AssignedUserReference = $value
                }
                & $factoryPath @parameters
            }
        ) | & $exportPath -Path $path
        $rows = @(Import-Csv -LiteralPath $path)

        foreach ($column in @('assetTag', 'deviceName', 'serialNumber', 'assignedUserReference')) {
            $rows[0].$column | Should -BeExactly ''
            $rows[1].$column | Should -BeExactly ''
            $rows[2].$column | Should -BeExactly ' '
        }
    }

    It 'uses a literal filename containing wildcard characters' {
        $path = Join-Path $TestDrive 'assets[1].csv'

        & $factoryPath -AssetId 'CMDB-LITERAL' | & $exportPath -Path $path

        (Import-Csv -LiteralPath $path).assetId | Should -BeExactly 'CMDB-LITERAL'
    }

    It 'rejects <Name> input before replacing a file or creating a new parent directory' -ForEach @(
        @{ Name = 'null'; Invalid = $null },
        @{ Name = 'missing properties'; Invalid = [pscustomobject]@{ assetId = 'CMDB-BAD' } },
        @{ Name = 'numeric reference'; Invalid = [pscustomobject]@{
            assetId = 'CMDB-BAD'; assetTag = $null; deviceName = $null
            serialNumber = $null; assignedUserReference = 42
        } },
        @{ Name = 'blank identity'; Invalid = [pscustomobject]@{
            assetId = ' '; assetTag = $null; deviceName = $null
            serialNumber = $null; assignedUserReference = $null
        } }
    ) {
        $path = Join-Path $TestDrive 'unchanged.csv'
        Set-Content -LiteralPath $path -Value 'existing data'
        $before = Get-Content -LiteralPath $path -Raw
        $valid = & $factoryPath -AssetId 'CMDB-VALID'

        { @($valid, $Invalid) | & $exportPath -Path $path } | Should -Throw
        (Get-Content -LiteralPath $path -Raw) | Should -BeExactly $before
        $newPath = Join-Path $TestDrive 'not-created/assets.csv'
        { & $exportPath -InputObject @($valid, $Invalid) -Path $newPath } | Should -Throw
        Test-Path -LiteralPath (Split-Path $newPath -Parent) | Should -BeFalse
    }

    It 'rejects empty arrays and empty pipelines before changing an existing file' {
        $path = Join-Path $TestDrive 'empty-input.csv'
        Set-Content -LiteralPath $path -Value 'existing data'
        $before = Get-Content -LiteralPath $path -Raw

        { & $exportPath -InputObject @() -Path $path } | Should -Throw '*at least one*'
        { @() | & $exportPath -Path $path } | Should -Throw '*at least one*'
        (Get-Content -LiteralPath $path -Raw) | Should -BeExactly $before
    }

    It 'rejects a blank destination' {
        { & $factoryPath | & $exportPath -Path ' ' } | Should -Throw
    }

    It 'reports a destination write failure' {
        { & $factoryPath | & $exportPath -Path $TestDrive } | Should -Throw
    }
}

Describe 'CMDB asset fixture' {
    BeforeAll {
        $factoryPath = Join-Path $PSScriptRoot 'New-FakeCmdbAsset.ps1'
        $exportPath = Join-Path $PSScriptRoot 'Export-FakeCmdbAsset.ps1'
        $fixturePath = Join-Path $PSScriptRoot '../../data/test-cmdb-assets.csv'
        $intunePath = Join-Path $PSScriptRoot '../../data/test-intune-devices.csv'
        $assets = @(Import-Csv -LiteralPath $fixturePath)
        $devices = @(Import-Csv -LiteralPath $intunePath)
    }

    It 'reproduces the versioned fixture with supplied values without modifying Intune' {
        $path = Join-Path $TestDrive 'generated/cmdb-assets.csv'
        $intuneBefore = Get-Content -LiteralPath $intunePath -Raw
        $assetParameters = @(
            @{
                AssetId = 'CMDB-ASSET-001'
                AssetTag = 'PAR-000001'
                DeviceName = 'SYNTH-ASSIGNED-001'
                SerialNumber = 'SYNTH-000001'
                AssignedUserReference = 'CMDB-PERSON-001'
            }
            @{
                AssetId = 'CMDB-ASSET-002'
                AssetTag = 'PAR-000002'
                DeviceName = 'SYNTH-SHARED-001'
                SerialNumber = 'SYNTH-000003'
                AssignedUserReference = 'CMDB-PERSON-002'
            }
            @{
                AssetId = 'CMDB-ASSET-003'
                AssetTag = 'PAR-000003'
                DeviceName = 'SYNTH-SHARED-001'
                SerialNumber = 'SYNTH-000003'
            }
        )

        foreach ($attempt in 1..2) {
            $generatedAssets = @(
                foreach ($parameters in $assetParameters) {
                    & $factoryPath @parameters
                }
            )
            $output = @($generatedAssets | & $exportPath -Path $path)

            $output | Should -HaveCount 0
            (Get-Content -LiteralPath $path -Raw) | Should -BeExactly (Get-Content -LiteralPath $fixturePath -Raw)
        }
        (Get-Content -LiteralPath $intunePath -Raw) | Should -BeExactly $intuneBefore
    }

    It 'has separate stable asset identities and only descriptive source columns' {
        $assets | Should -HaveCount 3
        @($assets.assetId | Select-Object -Unique) | Should -HaveCount 3
        ($assets.assetId -join ',') | Should -BeExactly 'CMDB-ASSET-001,CMDB-ASSET-002,CMDB-ASSET-003'
        foreach ($asset in $assets) {
            ($asset.PSObject.Properties.Name -join ',') | Should -BeExactly (
                'assetId,assetTag,deviceName,serialNumber,assignedUserReference'
            )
            $asset.assetId | Should -Not -Be $asset.assetTag
            $devices.id | Should -Not -Contain $asset.assetId
        }
    }

    It 'provides one unique name and serial candidate for the assigned Intune device' {
        $device = $devices | Where-Object deviceName -EQ 'SYNTH-ASSIGNED-001'
        $candidates = @($assets | Where-Object serialNumber -EQ $device.serialNumber)

        $candidates | Should -HaveCount 1
        $candidates[0].assetId | Should -BeExactly 'CMDB-ASSET-001'
        $candidates[0].deviceName | Should -BeExactly $device.deviceName
        $candidates[0].assignedUserReference | Should -BeExactly 'CMDB-PERSON-001'
    }

    It 'intentionally has no name or serial candidate for the unassigned Intune device' {
        $device = $devices | Where-Object deviceName -EQ 'SYNTH-UNASSIGNED-001'

        @($assets | Where-Object serialNumber -EQ $device.serialNumber) | Should -HaveCount 0
        @($assets | Where-Object deviceName -EQ $device.deviceName) | Should -HaveCount 0
    }

    It 'has two shared-device candidates with distinct IDs and present and missing CMDB references' {
        $device = $devices | Where-Object deviceName -EQ 'SYNTH-SHARED-001'
        $candidates = @($assets | Where-Object serialNumber -EQ $device.serialNumber)

        $candidates | Should -HaveCount 2
        ($candidates.assetId -join ',') | Should -BeExactly 'CMDB-ASSET-002,CMDB-ASSET-003'
        foreach ($candidate in $candidates) {
            $candidate.deviceName | Should -BeExactly $device.deviceName
        }
        $candidates[0].assignedUserReference | Should -BeExactly 'CMDB-PERSON-002'
        $candidates[1].assignedUserReference | Should -BeExactly ''
    }
}
