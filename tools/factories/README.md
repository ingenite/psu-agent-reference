# Synthetic device factories

Run these tools locally with PowerShell 7.1 or later and
`Microsoft.Graph.DeviceManagement` version 2.41.2 installed. They do not authenticate
or make Graph requests. The Authentication dependency loads with the SDK.

`New-FakeIntuneDevice.ps1` returns one SDK managed-device model. It accepts the 15
properties used by the initial Intune report. Device name is required; identifiers
are generated and timestamps default to now and 30 days before now. Supply explicit
values when records must be repeatable. User association defaults to null; enrollment
type is omitted unless supplied. Construction uses the SDK's JSON deserializer to
populate read-only fields.

`Export-FakeIntuneDevice.ps1` accepts these models through the pipeline or
`-InputObject`. It writes the 15 selected columns to `data/intune-devices.csv` by
default, or to `-Path`, replacing the existing file. Add `-Append` to retain existing
rows and add new ones; a missing file is created. Append does not deduplicate device
IDs. An incompatible existing header is rejected by `Export-Csv`. It creates the
parent directory when needed. Dates are UTC ISO 8601 strings and enrollment type is text.

CSV does not retain SDK types or distinguish null from an empty string. A future
retrieval provider must parse dates, restore model types, and treat empty user
association cells as missing. The factory itself preserves null, empty, and
whitespace user IDs. The retrieval provider and reporting UI are not implemented.

## Create a dataset

From the repository root:

```powershell
$common = @{
    EnrolledDateTime = '2026-09-01T12:00:00Z'
    LastSyncDateTime = '2026-10-24T18:30:00Z'
    DeviceEnrollmentType = 'unknown'
}

$devices = @(
    & ./tools/factories/New-FakeIntuneDevice.ps1 @common `
        -DeviceName SYNTH-ASSIGNED-001 -SerialNumber SYNTH-000001 `
        -Id '20000000-0000-4000-8000-000000000001' `
        -AzureAdDeviceId '30000000-0000-4000-8000-000000000001' `
        -UserId '10000000-0000-4000-8000-000000000001' `
        -UserPrincipalName 'alex@example.invalid' -EmailAddress 'alex@example.invalid' `
        -UserDisplayName 'Alex Example'
    & ./tools/factories/New-FakeIntuneDevice.ps1 @common `
        -DeviceName SYNTH-UNASSIGNED-001 -SerialNumber SYNTH-000002 `
        -Id '20000000-0000-4000-8000-000000000002' `
        -AzureAdDeviceId '30000000-0000-4000-8000-000000000002'
    & ./tools/factories/New-FakeIntuneDevice.ps1 @common `
        -DeviceName SYNTH-SHARED-001 -SerialNumber SYNTH-000003 `
        -Id '20000000-0000-4000-8000-000000000003' `
        -AzureAdDeviceId '30000000-0000-4000-8000-000000000003'
)

$devices | & ./tools/factories/Export-FakeIntuneDevice.ps1
```

To add another generated device to that CSV:

```powershell
& ./tools/factories/New-FakeIntuneDevice.ps1 -DeviceName SYNTH-EXTRA-001 |
    & ./tools/factories/Export-FakeIntuneDevice.ps1 -Append
```

The checked-in [dataset](../../data/intune-devices.csv) contains these three records.
The first has a primary-user association; the other two do not. The shared device
represents an intentionally userless scenario. Missing association is descriptive,
not automatically a defect. All enrollment types are `unknown`; the examples do
not claim a verified mapping from Autopilot deployment modes.

## Offline verification

```powershell
Invoke-Pester -Path ./tools/factories -Output Detailed
& ./tools/factories/Test-IntuneDeviceModel.ps1
```

The retained model probe compares JSON and dictionary construction and JSON round
trips across six scenarios. It writes its summary, fixtures, property metadata,
and comparisons to `tools/output/`, which is ignored by Git. Dictionary null-to-empty
conversions are recorded as observations; JSON paths must preserve all tested values
and the SDK model interface. No live tenant or enrollment behavior is verified.
