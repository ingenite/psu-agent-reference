# Windows Intune devices without a primary user

## Synopsis

Use `ParReports` to retrieve a report or transform devices already in memory.
The example demonstrates a reusable query that a script, endpoint, or dashboard
can consume without taking responsibility for fixture storage.

## Requirements and configuration

Use PowerShell 7.1 or later. The retrieval command uses ParData's existing
configuration, including `$PAR_FixturePaths` or repository-relative defaults.
Configure retrieval as described in the Intune fixture guide. Transforming
supplied objects requires neither ParData nor Graph; importing ParReports alone
does not load either dependency.

## Examples

From the repository root:

```powershell
Import-Module ./modules/ParReports/ParReports.psd1
$report = @(Get-ParIntuneDeviceWithoutPrimaryUserReport)
$report | Select-Object DeviceName, IntuneDeviceId, UserId
```

For objects already retrieved:

```powershell
Import-Module ./modules/ParData/ParData.psd1
$devices = @(Get-ParIntuneDevice)
$report = @($devices | ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport)
```

The same transformation accepts an array through `-InputObject`. Use `@(...)`
when a collection is needed, including zero or one row. Command help owns the
selection rule, report fields, and error behavior:

```powershell
Get-Help Get-ParIntuneDeviceWithoutPrimaryUserReport -Full
Get-Help ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport -Full
```

## Interpretation

The checked-in fixture produces `SYNTH-UNASSIGNED-001` and `SYNTH-SHARED-001`;
`SYNTH-ASSIGNED-001` is excluded. An intentionally userless device can match.
Missing association is descriptive and does not establish a defect or a required
remediation. Preserve device identifiers when adapting the report so an
administrator can investigate the original records.

The demonstration uses the source `UserId`; live primary-user semantics and
other evidence gaps are recorded in errata, available from the index.

## Verification

```powershell
Invoke-Pester -Path ./modules/ParReports -Output Detailed
```

Tests cover selection, output fields, source preservation, empty input, retrieval
success and failure, and integration with the checked-in fixture and installed SDK.
