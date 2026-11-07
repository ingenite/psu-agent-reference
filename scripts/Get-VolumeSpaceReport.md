# Get-VolumeSpaceReport.ps1

Reports on three synthetic volumes; it does not inspect the host's disks.
Run with no parameters for a 20 percent minimum, or set `MinimumFreePercent`
to another integer from 0 to 100. Exactly meeting the minimum is `OK`.
In PSU, Quick Run omits the optional parameter. The Run Script form supplies its
numeric field (initially 0 in the checked instance), so enter 20 or another
intended threshold explicitly there.
The job's Pipeline Output contains a JSON string with `Name`, `FreePercent`,
and `Status`. Locally, pipe it to `ConvertFrom-Json` to work with objects, or call
the module's `Get-ParVolumeReport` directly.

The resource imports `ParVolumeReport` and calls `Get-ParVolumeReport`.
Reading and assessment live in separate commands, the reader can be replaced,
and the API endpoint calls the same rule. The collection guide is
`docs/design-principles.md`; parameter contracts are in PowerShell help.
