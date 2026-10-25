# Synthetic device factories

## Synopsis

Create synthetic SDK device models and export a dataset for the retrieval and
reporting examples. Use explicit identifiers and timestamps for repeatable records.

## Requirements

Run locally with PowerShell 7.1 or later and
`Microsoft.Graph.DeviceManagement` version 2.41.2 installed. They do not authenticate
or make Graph requests. The Authentication dependency loads with the SDK.

Command help owns defaults, parameters, output, and export behavior. The exporter
replaces the destination unless `-Append` is supplied. Review the path before
running a dataset example. The Intune fixture guide owns the CSV format contract.

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

The checked-in `data/intune-devices.csv` contains these three records.
The first has a primary-user association; the other two do not. The shared device
represents an intentionally userless scenario. Missing association is descriptive,
not automatically a defect. All enrollment types are `unknown`.

## Reference and verification

```powershell
Get-Help ./tools/factories/New-FakeIntuneDevice.ps1 -Full
Get-Help ./tools/factories/Export-FakeIntuneDevice.ps1 -Full
Invoke-Pester -Path ./tools/factories -Output Detailed
& ./tools/factories/Test-IntuneDeviceModel.ps1
```

The retained model probe compares JSON and dictionary construction and JSON round
trips across six scenarios. It writes its summary, fixtures, property metadata,
and comparisons to `tools/output/`, which is ignored by Git. Dictionary null-to-empty
conversions are recorded as observations; JSON paths must preserve all tested values
and the SDK model interface. Project-wide verification gaps are recorded in
errata, available from the documentation index.
