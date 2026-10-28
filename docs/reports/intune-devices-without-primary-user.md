# Windows Intune devices without a primary user

## Synopsis

Use `ParReports` to retrieve a report or transform devices already in memory.
The example demonstrates a reusable query that a script, endpoint, or dashboard
can consume without taking responsibility for fixture storage.

## Configuration

Configure ParData as described in the fixture retrieval guide. Transforming
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
when a collection is needed, including zero or one row.

## Interpretation

Primary User is the intended terminology for the single-user Windows device
scenario. Intune's UserDisplayName and UserPrincipalName provide recorded display
context; UserId is the identity key corresponding to Entra user Id. The report
selects missing UserId values and does not infer identity from display fields.

The shared demonstration data produces `SYNTH-COMPARE-NO-INTUNE-USER`,
`SYNTH-COMPARE-SHARED`, `SYNTH-COMPARE-NO-ASSET`, and `SYNTH-COMPARE-NO-MAPPING`.
Devices with a nonblank user ID are excluded. An intentionally userless device
can match.
Missing association is descriptive and does not establish a defect or a required
remediation. Preserve device identifiers when adapting the report so an
administrator can investigate the original records.
