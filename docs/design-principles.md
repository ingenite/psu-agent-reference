# Software-design principles in a volume-space report

This example checks three made-up disks. Each has a name, total capacity, and free
space. Free space below 20 percent is `Low`; 20 percent or more is `OK`. No actual
disks are inspected or changed.

Run from the repository root:

```powershell
Import-Module ./modules/ParVolumeReport/ParVolumeReport.psd1
Get-ParVolumeReport
```

```text
Name   FreePercent Status
----   ----------- ------
Demo-C          10 Low
Demo-D          20 OK
Demo-E          60 OK
```

## Follow the code

Open `modules/ParVolumeReport/ParVolumeReport.psm1`:

1. `Get-ParDemoVolume` creates three records containing `Name`, `CapacityGB`, and
   `FreeGB`. For example, Demo-D has 200 GB capacity and 40 GB free.
2. `Get-ParVolumeAssessment` calculates `100 * FreeGB / CapacityGB`, then compares
   that percentage with the minimum. Demo-D has 20 percent free, so it is `OK`.
3. `Get-ParVolumeReport` runs those two functions in order and returns the results.
   Set `-MinimumFreePercent 30` and Demo-D becomes `Low`.

| Principle | The useful choice in this code |
| --- | --- |
| Separation of concerns | Getting disk data and deciding whether space is low are separate functions. Change either without rewriting the other. |
| Pure functions | The calculation uses the supplied records and minimum, returns new records, and leaves the originals unchanged. The same inputs give the same answer. |
| Dependency injection | Pass different code for getting disk data into `Get-ParVolumeReport`, rather than editing that function. |
| Don't repeat yourself (DRY) | A PSU automation script and API endpoint use this same report. The comparison and default minimum each have one home. |

For dependency injection, `-ReadVolume` accepts the code inside `{ ... }` below.
It supplies one disk record in place of the three demonstration records:

```powershell
Get-ParVolumeReport -ReadVolume {
    [pscustomobject]@{ Name = 'Alternate'; CapacityGB = 80; FreeGB = 20 }
} -MinimumFreePercent 30
# Alternate: 25% free, Low
```

Three functions add names to follow. They are useful here because two PSU
resources share the report and its data can be replaced. A disposable report
with one use could reasonably remain a single script.

## Use in PSU

- **Automation:** `scripts/Get-VolumeSpaceReport.ps1`. Use **Quick Run** for the
  default minimum. **Run Script** initially shows `0` in the checked instance;
  enter your intended minimum. Results appear in **Pipeline Output** as JSON.
- **API:** `endpoints/Get-VolumeSpaceReport.ps1`. Call
  `/api/par/v1/design/volume-space`, optionally adding `?MinimumFreePercent=30`.
  It returns JSON and serves only synthetic data without authentication.

The module returns PowerShell objects. The automation script converts them to
JSON because saved job output lost their properties in the checked PSU instance.
The endpoint uses PSU's `$Repository` variable to load the module because
`$PSScriptRoot` was empty there.

Local PowerShell and PSU 2026.3.0 checks verified the synthetic results. Pester
tests guard against accidental behavior changes; they are project checks you
can leave aside while reading the example. No live disk integration is included.
Use `Get-Help Get-ParVolumeReport -Full` for parameter details and data assumptions.
