# Windows Intune devices without a primary user

`ParReports` provides a reusable query for scripts, endpoints, and dashboards under
[issue #20](https://github.com/ingenite/psu-agent-reference/issues/20). It requires
PowerShell 7.1 or later and lives in top-level `modules/` because its commands are
shared across PSU resources. Dashboard-only helpers belong in dashboard companion
modules. No presentation or PSU resource registration is included here.

## Command contract

From the repository root:

```powershell
Import-Module ./modules/ParReports/ParReports.psd1
$report = @(Get-ParIntuneDeviceWithoutPrimaryUserReport)
```

`Get-ParIntuneDeviceWithoutPrimaryUserReport` takes no storage parameters. It loads
the sibling `ParData` module and calls `Get-ParIntuneDevice` once per invocation.
Configure that module through its existing
[fixture retrieval contract](../setup/intune-fixture-retrieval.md), including the
shared `$PAR_FixturePaths` variable and repository-relative development defaults.
An explicitly configured ParData import is retained; the query does not force a
reimport. There are no report-specific shared variables or fixture paths.

The query buffers retrieval before transformation. Terminating errors propagate,
and nonterminating retrieval errors are promoted to terminating errors. Even if a
provider emits some devices before failing, the query emits no partial report.
Successful retrieval with no source records or no matching records emits no rows.
Use `@(...)` to collect zero, one, or multiple rows consistently.

For already retrieved objects, use the transformation directly:

```powershell
$devices = @(Get-ParIntuneDevice)
$report = @(ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport -InputObject $devices)
# Pipeline input is also supported.
$report = @($devices | ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport)
```

`ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport` accepts source objects with the
properties returned by `Get-ParIntuneDevice`. It can also accept equivalent supplied
objects for isolated tests. It performs no retrieval and requires no Graph module.
Importing `ParReports` alone does not load ParData or Graph. The current retrieval
provider requires installed `Microsoft.Graph.DeviceManagement` **2.41.2**; it does
not authenticate or make Graph requests.

## Selection and report fields

Selection requires `OperatingSystem -eq 'Windows'` (case-insensitive exact equality)
and a null, empty, or whitespace-only `UserId`. Other OS labels, including null or
blank values, do not match. Display name, email, UPN, device name, and enrollment
type never determine assignment. A nonblank user ID excludes the device even if
all user display fields are empty.

This is the demonstration's rule for a missing primary-user association, based on
the source `userId`. Microsoft's
[managedDevice reference](https://learn.microsoft.com/en-us/graph/api/resources/intune-devices-manageddevice?view=graph-rest-1.0)
documents that property as the associated user's identifier and separately
documents the `users` relationship for primary users. This query does not inspect
that relationship or resolve users; live primary-user semantics remain unverified.
Intentionally userless/shared devices can match. A match is descriptive and does
not establish a defect or a required remediation.

Each match produces a new `PSCustomObject` with these fields:

| Report field | Meaning and source |
| --- | --- |
| `IntuneDeviceId` | Original `Id` of the Intune managed-device record, retained for investigation links. |
| `AzureAdDeviceId` | Original Entra device identifier; distinct from the Intune record ID. |
| `DeviceName` | Source device name. |
| `SerialNumber`, `Manufacturer`, `Model` | Source hardware identity and context. |
| `OperatingSystem`, `OSVersion` | Source OS label and version. |
| `DeviceEnrollmentType` | Source enrollment type converted to text; empty when absent. No enrollment-mode inference. |
| `EnrolledDateTime` | Source enrollment timestamp; null remains null. |
| `LastSyncDateTime` | Source timestamp of the last successful Intune sync (check-in context); null remains null. |
| `UserId` | Original missing association value, preserving null, empty, or whitespace for inspection. |

Timestamps retain their source types and values; the fixture provider restores UTC
SDK date values. Rows preserve source order and duplicates. The transformation
does not modify source objects, calculate staleness, generate links, or attach
severity. Empty arrays, null input, null elements, and empty pipelines emit no rows.
Supplied non-null objects must expose the source properties used by the report;
this command does not repair incomplete source models.

## Offline verification

```powershell
Invoke-Pester -Path ./modules/ParReports -Output Detailed
git diff --check
```

Sibling tests cover selection, report fields, source preservation, empty input,
retrieval success and failure, and the checked-in fixture through the installed
SDK. The fixture returns `SYNTH-UNASSIGNED-001` and the intentionally userless
`SYNTH-SHARED-001`; `SYNTH-ASSIGNED-001` is excluded. These checks do not verify live
Graph, PSU variable injection, or PSU resource execution. CMDB correlation, Entra
user resolution, dashboard UI, HTTP endpoints, and runtime configuration remain
subsequent work.
