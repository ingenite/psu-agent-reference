Describe 'New-FakeCmdbAsset' {
    BeforeAll {
        $factoryPath = Join-Path $PSScriptRoot 'New-FakeCmdbAsset.ps1'
        $columns = 'assetId,assetTag,deviceName,serialNumber,assignedUserReference'
    }

    It 'returns one plain source object with a generated identity and null optional fields' {
        $assets = @(& $factoryPath)

        $assets | Should -HaveCount 1
        $asset = $assets[0]
        $asset | Should -BeOfType [pscustomobject]
        ($asset.PSObject.Properties.Name -join ',') | Should -BeExactly $columns
        $asset.assetId | Should -Match '^[0-9a-f-]{36}$'
        foreach ($column in @('assetTag', 'deviceName', 'serialNumber', 'assignedUserReference')) {
            ($null -eq $asset.$column) | Should -BeTrue
        }
        $second = & $factoryPath
        $second.assetId | Should -Not -Be $asset.assetId
    }

    It 'preserves opaque supplied identifiers and all descriptive values on repeated calls' {
        $parameters = @{
            AssetId = 'CMDB-ASSET-001'
            AssetTag = 'PAR-000001'
            DeviceName = 'SYNTH-ASSIGNED-001'
            SerialNumber = 'SYNTH-000001'
            AssignedUserReference = 'CMDB-PERSON-001'
        }
        $first = & $factoryPath @parameters
        $second = & $factoryPath @parameters

        foreach ($column in $parameters.Keys) {
            $first.$column | Should -BeExactly $parameters[$column]
            $second.$column | Should -BeExactly $first.$column
        }
        $first.assetId | Should -Not -Be $first.assetTag
        $first.assignedUserReference | Should -BeExactly 'CMDB-PERSON-001'
    }

    It 'preserves <Name> optional values without inferring correlation or assignment' -ForEach @(
        @{ Name = 'null'; Value = $null },
        @{ Name = 'empty'; Value = '' },
        @{ Name = 'whitespace'; Value = '   ' }
    ) {
        $parameters = @{
            AssetId = 'CMDB-ASSET-001'
            AssetTag = $Value
            DeviceName = $Value
            SerialNumber = $Value
            AssignedUserReference = $Value
        }
        $asset = & $factoryPath @parameters

        foreach ($column in @('assetTag', 'deviceName', 'serialNumber', 'assignedUserReference')) {
            if ($null -eq $Value) {
                ($null -eq $asset.$column) | Should -BeTrue
            }
            else {
                $asset.$column | Should -BeExactly $Value
            }
        }
    }

    It 'does not derive identity from device attributes or person references' {
        $parameters = @{
            AssetId = 'CMDB-ASSET-001'
            DeviceName = 'SYNTH-SHARED-001'
            SerialNumber = 'SYNTH-000003'
            AssignedUserReference = 'CMDB-PERSON-001'
        }
        $first = & $factoryPath @parameters
        $parameters.AssetId = 'CMDB-ASSET-002'
        $parameters.AssignedUserReference = $null
        $second = & $factoryPath @parameters
        $parameters.AssetId = $first.assetId
        $parameters.DeviceName = 'SYNTH-RENAMED'
        $parameters.SerialNumber = 'SYNTH-REVISED'
        $parameters.AssignedUserReference = 'CMDB-PERSON-002'
        $renamed = & $factoryPath @parameters

        $second.assetId | Should -Not -Be $first.assetId
        $renamed.assetId | Should -BeExactly $first.assetId
        ($renamed.PSObject.Properties.Name -join ',') | Should -BeExactly $columns
    }

    It 'rejects a <Name> asset identifier' -ForEach @(
        @{ Name = 'null'; Value = $null },
        @{ Name = 'empty'; Value = '' },
        @{ Name = 'whitespace'; Value = '   ' },
        @{ Name = 'numeric'; Value = 42 },
        @{ Name = 'collection'; Value = @('one', 'two') }
    ) {
        { & $factoryPath -AssetId $Value } | Should -Throw
    }

    It 'rejects non-string <Property> values' -ForEach @(
        @{ Property = 'AssetTag' },
        @{ Property = 'DeviceName' },
        @{ Property = 'SerialNumber' },
        @{ Property = 'AssignedUserReference' }
    ) {
        $parameters = @{ $Property = 42 }
        { & $factoryPath @parameters } | Should -Throw '*must be a string or null*'
    }
}
