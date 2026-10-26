# Fixture generation

Create synthetic Intune device and Entra user SDK models and plain PowerShell
CMDB asset records for the retrieval and reporting examples. Use explicit
identifiers and timestamps where applicable for repeatable records. Factories
create objects in memory; exporters write the selected source fields to CSV.

The examples below regenerate the checked-in fixtures from the repository root.
They replace the destination CSVs. To create a separate dataset, supply `-Path`
to the exporter, for example `-Path ./tools/output/example-assets.csv`.

## Create an Intune dataset

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

## Create a CMDB dataset

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

## Create an Entra user dataset

```powershell
$userParameters = @(
    @{
        Id = '10000000-0000-4000-8000-000000000001'
        DisplayName = 'Alex Example'
        UserPrincipalName = 'alex@example.invalid'
        Mail = 'alex@example.invalid'
        AccountEnabled = $true
    }
    @{
        Id = '10000000-0000-4000-8000-000000000002'
        DisplayName = 'Blair Sample'
        UserPrincipalName = 'blair@example.invalid'
        AccountEnabled = $false
    }
    @{
        Id = '10000000-0000-4000-8000-000000000003'
        DisplayName = 'Casey Demo'
    }
)

$users = @(
    foreach ($parameters in $userParameters) {
        & ./tools/factories/New-FakeEntraUser.ps1 @parameters
    }
)

$users | & ./tools/factories/Export-FakeEntraUser.ps1
```

## Fixture scenarios

The Intune fixture covers an assigned device, a device with no user association,
and an intentionally userless shared device. All enrollment types are `unknown`.

The CMDB fixture intentionally has these relationships to the Intune data:

| Intune device | CMDB fixture records |
| --- | --- |
| `SYNTH-ASSIGNED-001`, serial `SYNTH-000001` | One candidate, `CMDB-ASSET-001`, with person reference `CMDB-PERSON-001`. |
| `SYNTH-UNASSIGNED-001`, serial `SYNTH-000002` | No record with that name or serial. |
| `SYNTH-SHARED-001`, serial `SYNTH-000003` | Two candidates with the same name and serial: `CMDB-ASSET-002` has person reference `CMDB-PERSON-002`; `CMDB-ASSET-003` has none. |

The Entra fixture covers Alex Example with the existing Intune `UserId`
`10000000-0000-4000-8000-000000000001` and `alex@example.invalid`, Blair Sample
with a false account state and missing mail, and Casey Demo with unspecified UPN,
mail, and account state. The separate `data/cmdb-person-mappings.csv` explicitly
maps `CMDB-PERSON-001` to `alex@example.invalid` and `CMDB-PERSON-002` to
`blair@example.invalid` for the assigned-user resolver. It can be recreated with:

```powershell
@(
    [pscustomobject]@{ personReference = 'CMDB-PERSON-001'; userPrincipalName = 'alex@example.invalid' }
    [pscustomobject]@{ personReference = 'CMDB-PERSON-002'; userPrincipalName = 'blair@example.invalid' }
) | Export-Csv -LiteralPath ./data/cmdb-person-mappings.csv -NoTypeInformation
```

These explicit demonstration mappings do not independently verify identity,
select a device candidate, or establish an assignment problem. Detailed resolution
behavior and composition examples are in `Get-Help Resolve-ParCmdbAssignedUser -Full`
after importing `ParReports`.

The CMDB projection draws on Atlassian's [hardware asset schema](https://support.atlassian.com/assets/docs/what-is-the-hardware-assets-system-schema/)
and [object attributes](https://support.atlassian.com/assets/docs/what-are-attributes/).
Its five-field flat schema is a demonstration choice, not an Atlassian API response.
The Entra fields follow Microsoft's [Graph user resource](https://learn.microsoft.com/en-us/graph/api/resources/user?view=graph-rest-1.0).
