# Design principles example

Software-design principles are easier to understand in a small, concrete example
than in the abstract. This one checks free space on three made-up disks: below
20 percent is `Low`, otherwise `OK`.

```powershell
Import-Module ./modules/ParVolumeReport/ParVolumeReport.psd1
Get-ParVolumeReport
```

| Principle | What it buys you here |
| --- | --- |
| Separation of concerns | Reading disk data and judging it are separate functions, so you can change one without touching the other. |
| Pure functions | The judgment uses only its inputs and returns new objects. The same input always gives the same answer, which makes it easy to test. |
| Dependency injection | `-ReadVolume` accepts a different data source, so the report logic never changes when the source does. |
| Don't repeat yourself | A PSU script and an API endpoint share one report and one threshold. |

## When not to do this

Three functions are more to read than one script. The split pays off here because
two PSU resources share the logic and the data source can change. A one-off report
with a single use could reasonably stay as one script.

## In PSU

- **Script:** `scripts/Get-VolumeSpaceReport.ps1` returns JSON, because PSU
  2026.3.0 lost object properties in saved job output.
- **API:** `GET /api/par/v1/design/volume-space?MinimumFreePercent=30`. It serves
  synthetic data only and has no authentication.
