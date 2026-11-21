<!-- Experimental only; not reference material for creating production PSU resources. -->
# PSU benchmark harness

Results: `Findings.md` covers PSU runtime choices; `DatabaseProviders.md` covers
application databases. The findings are the useful part. The scripts exist so the
results can be reproduced, and the owner approved .NET hashing, generic
collections and Stopwatch timing for this experiment only.

Run only against the dedicated `C:\dev-psu` instance, from the repository root in
PowerShell 7, with the `dev-psu-codex-mgmt-api` vault secret. Setup backs up the
development registrations; restore checks their hashes and won't overwrite later
work. Use a new pass name each time, because evidence is never overwritten. Results
go to ignored `tools/output/benchmarks/`.

```powershell
./tools/benchmarks/Set-BenchmarkPreview.ps1
./tools/benchmarks/Invoke-Benchmark.ps1 -Pass my-pass -Repetitions 5
./tools/benchmarks/Export-BenchmarkStorage.ps1 -Pass my-pass
./tools/benchmarks/Measure-Benchmark.ps1 -Pass my-pass
./tools/benchmarks/Test-BenchmarkEvidence.ps1 -Pass my-pass
./tools/benchmarks/Invoke-AdminBenchmark.ps1 -Pass my-admin
./tools/benchmarks/Measure-AdminBenchmark.ps1 -Pass my-admin
./tools/benchmarks/Test-AdminEvidence.ps1 -Pass my-admin
./tools/benchmarks/Set-BenchmarkPreview.ps1 -Restore
```

Export storage before cache expiry (two hours) or job-history grooming. `-Group`
on `Invoke-Benchmark.ps1` and `Invoke-AdminBenchmark.ps1` selects focused passes;
`Get-Help` shows the allowed groups and count parameters. `Test-BenchmarkDriver.ps1`
repeats the load case with a second, asynchronous HTTP driver.

Dashboard callbacks are measured by hand. Setup creates an app at
`http://127.0.0.1:5100/par-benchmarks`. Click **Run next sample** once per plan
entry, then copy the plan, the dashboard JSON from `C:\dev-psu\bench-results` and
the matching `Request finished` log lines into the pass. Run
`New-DashboardPlan.ps1` and restart the app before a new plan.

The database harness is archived in `database/DatabaseHarness.zip`, so its
unmaintained scripts stay out of analysis. Extract it before use:

```powershell
Expand-Archive -LiteralPath ./tools/benchmarks/database/DatabaseHarness.zip -DestinationPath ./tools/benchmarks/database
```

Retained passes: pass2, collections-isolated, set-difference, serialization,
longer-load, driver-host, dashboard-initial, dashboard-load and admin-*.
Incomplete discovery passes are excluded.
