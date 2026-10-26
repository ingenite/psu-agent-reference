# Synthetic data factories

## Synopsis

Create synthetic Intune SDK device models and plain PowerShell CMDB asset records
for the retrieval and reporting examples. Use explicit identifiers and timestamps
where applicable for repeatable records.

## Requirements

Run locally with PowerShell 7.1 or later. Intune tools also require
`Microsoft.Graph.DeviceManagement` version 2.41.2 installed; its Authentication
dependency loads with the SDK. CMDB tools require no additional modules. The
tools do not authenticate or make service requests.

Command help owns defaults, parameters, output, and export behavior. Both exporters
replace the destination unless `-Append` is supplied. Append retains existing rows
without deduplicating IDs and creates a missing CSV. Review the path before running
a dataset example. The Intune fixture guide owns the Intune CSV format contract.

## Create an Intune dataset

From the repository root:

```powershell
$common = @{
    EnrolledDateTime = '2026-09-01T12:00:00Z'
    LastSyncDateTime = '2026-10-24T18:30:00Z'
    DeviceEnrollmentType = 'unknown'
}

$deviceParameters = @(
    @{
        DeviceName = 'SYNTH-ASSIGNED-001'
        SerialNumber = 'SYNTH-000001'
        Id = '20000000-0000-4000-8000-000000000001'
        AzureAdDeviceId = '30000000-0000-4000-8000-000000000001'
        UserId = '10000000-0000-4000-8000-000000000001'
        UserPrincipalName = 'alex@example.invalid'
        EmailAddress = 'alex@example.invalid'
        UserDisplayName = 'Alex Example'
    }
    @{
        DeviceName = 'SYNTH-UNASSIGNED-001'
        SerialNumber = 'SYNTH-000002'
        Id = '20000000-0000-4000-8000-000000000002'
        AzureAdDeviceId = '30000000-0000-4000-8000-000000000002'
    }
    @{
        DeviceName = 'SYNTH-SHARED-001'
        SerialNumber = 'SYNTH-000003'
        Id = '20000000-0000-4000-8000-000000000003'
        AzureAdDeviceId = '30000000-0000-4000-8000-000000000003'
    }
)

$devices = @(
    foreach ($parameters in $deviceParameters) {
        & ./tools/factories/New-FakeIntuneDevice.ps1 @common @parameters
    }
)

$devices | & ./tools/factories/Export-FakeIntuneDevice.ps1
```

To add another generated device to that CSV:

```powershell
& ./tools/factories/New-FakeIntuneDevice.ps1 -DeviceName SYNTH-EXTRA-001 |
    & ./tools/factories/Export-FakeIntuneDevice.ps1 -Append
```

The checked-in `data/intune-devices.csv` contains these three records.
The first has a primary-user association; the other two do not. The shared device
represents an intentionally userless scenario. Missing association is descriptive,
not automatically a defect. All enrollment types are `unknown`.

## Create a CMDB dataset

From the repository root, regenerate `data/cmdb-assets.csv`:

```powershell
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

$assets = @(
    foreach ($parameters in $assetParameters) {
        & ./tools/factories/New-FakeCmdbAsset.ps1 @parameters
    }
)

$assets | & ./tools/factories/Export-FakeCmdbAsset.ps1
```

This supplies fixed values to `New-FakeCmdbAsset.ps1` and exports through
`Export-FakeCmdbAsset.ps1`. To export these assets to a separate file:

```powershell
$assets | & ./tools/factories/Export-FakeCmdbAsset.ps1 -Path ./tools/output/example-assets.csv
```

To append another asset to that example CSV:

```powershell
& ./tools/factories/New-FakeCmdbAsset.ps1 -AssetId 'CMDB-ASSET-EXTRA' |
    & ./tools/factories/Export-FakeCmdbAsset.ps1 -Path ./tools/output/example-assets.csv -Append
```

The model draws on Atlassian's [hardware asset schema](https://support.atlassian.com/assets/docs/what-is-the-hardware-assets-system-schema/)
for inventory labels, hostnames, manufacturer serials, and person references,
and its [object attributes](https://support.atlassian.com/assets/docs/what-are-attributes/)
for stable object identity. The five-field flat schema and opaque identifier
formats are demonstration choices, not an Atlassian API representation. Command
help defines each field. Device correlation and person mapping remain separate;
a CMDB person reference is not assumed to be an Entra user ID.

The checked-in fixture intentionally has these relationships to the Intune data:

| Intune device | CMDB fixture records |
| --- | --- |
| `SYNTH-ASSIGNED-001`, serial `SYNTH-000001` | One candidate, `CMDB-ASSET-001`, with person reference `CMDB-PERSON-001`. |
| `SYNTH-UNASSIGNED-001`, serial `SYNTH-000002` | No record with that name or serial. |
| `SYNTH-SHARED-001`, serial `SYNTH-000003` | Two candidates with the same name and serial: `CMDB-ASSET-002` has person reference `CMDB-PERSON-002`; `CMDB-ASSET-003` has none. |

All asset IDs and inventory tags are fixed and distinct. These relationships
support later tests without selecting a candidate, resolving a person reference,
or establishing assignment matches or mismatches. The shared Intune device remains
intentionally userless; the CMDB records do not establish an assignment problem.

## Reference and verification

```powershell
Get-Help ./tools/factories/New-FakeIntuneDevice.ps1 -Full
Get-Help ./tools/factories/Export-FakeIntuneDevice.ps1 -Full
Get-Help ./tools/factories/New-FakeCmdbAsset.ps1 -Full
Get-Help ./tools/factories/Export-FakeCmdbAsset.ps1 -Full
Invoke-Pester -Path ./tools/factories -Output Detailed
& ./tools/factories/Test-IntuneDeviceModel.ps1
```

The retained model probe compares JSON and dictionary construction and JSON round
trips across six scenarios. It writes its summary, fixtures, property metadata,
and comparisons to `tools/output/`, which is ignored by Git. Dictionary null-to-empty
conversions are recorded as observations; JSON paths must preserve all tested values
and the SDK model interface. Project-wide verification gaps are recorded in
errata, available from the documentation index. CMDB tests cover optional values,
repeatable identifiers, CSV export, invalid input before writes, exact fixture
regeneration, and the intentional relationships above.
