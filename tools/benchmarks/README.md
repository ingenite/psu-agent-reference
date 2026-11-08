<!-- Experimental only; not reference material for creating production PSU resources. -->
# PSU benchmark harness

Run only against the dedicated `C:\dev-psu` instance. Findings.md covers the four
initial questions; AdminScenarios.md covers common admin tasks and crossover ranges.

PowerShell keeps workloads readable and comparable across jobs, endpoints, and
callbacks. Stopwatch measures elapsed time, JSONL retains samples, and the bundled
SQLite provider reads stored payload sizes. No additional dependencies were needed.
The owner authorized .NET hashing, generic collections, and measurement for this
experiment.

## Run and restore

From the repository root, use PowerShell 7 with access to the existing
`dev-psu-codex-mgmt-api` vault secret:

```powershell
./tools/benchmarks/Set-BenchmarkPreview.ps1
./tools/benchmarks/Invoke-Benchmark.ps1 -Pass my-pass -Repetitions 5
./tools/benchmarks/Export-BenchmarkStorage.ps1 -Pass my-pass
./tools/benchmarks/Measure-Benchmark.ps1 -Pass my-pass
./tools/benchmarks/Test-BenchmarkEvidence.ps1 -Pass my-pass
./tools/benchmarks/Set-BenchmarkPreview.ps1 -Restore
```

Use new pass names; raw samples are not overwritten. Results and source snapshots
stay under ignored `tools/output/benchmarks/`. Export and check storage before
cache expiry (two hours for the initial cases) or job-history grooming. Copy the
results directory to share the evidence.

Setup backs up the three development registration files. Restore checks their
hashes and refuses to repeat over later work. Unregistered scenario copies remain
in the development repository. The synchronized instance is not modified.

## Focused passes and summaries

`-Group` selects cache, hash, output, collections, difference, serialization, or load.
Each group has a warm-up followed by seeded, shuffled order. For the initial
follow-ups, use seven repetitions with collections, difference, or serialization.
For the longer load pass, use `-Group load -LoadIterations 1000000 -Repetitions 3`.
`Test-BenchmarkDriver.ps1 -Pass my-driver` uses a second, asynchronous HTTP driver.

`Measure-Benchmark.ps1` reports request distributions separately from burst counts.
Requests in one burst are correlated. `BatchWallMs` uses one observation per block,
location, and concurrency within the pass and case; older rows use their maximum
saved wall time. `DriverCycleRequestsPerSecond` includes dispatch and job evidence
collection after completion. `EndToEndMs` stops when the response or finished job
is observed, before diagnostic-file reads and pipeline downloads.

## Dashboard callbacks

Setup creates a seeded plan and native app at `http://127.0.0.1:5100/par-benchmarks`.
Click **Run next sample** once per plan entry, waiting for completion before each
click. For load, use **Run concurrent sample** for four sequential clicks, then four
rounds of simultaneous clicks in four tabs. Exclude the first sequential sample
and first concurrent round as warm-ups.

Copy the plan and matching dashboard JSON files from `C:\dev-psu\bench-results`
into a new pass directory. Retain matching `Request finished` log lines for
`benchmark-next` and `benchmark-load`; they measure backend HTTP handling, not
browser rendering. Before a new plan, run New-DashboardPlan.ps1 and restart the
benchmark app to reset its session index.

## Admin scenarios

After installing the preview, these commands reproduce the five plans with new
names. Directory users are synthetic; process inputs come from local Get-Process.
The scenarios inspect stored sizes and then remove their temporary cache keys.

```powershell
./tools/benchmarks/Invoke-AdminBenchmark.ps1 -Pass my-admin
./tools/benchmarks/Invoke-AdminBenchmark.ps1 -Pass my-cache-boundary -Group cache -DirectoryCounts 2,3,4 -ProcessCounts @()
./tools/benchmarks/Invoke-AdminBenchmark.ps1 -Pass my-report-boundary -Group report -ReportCounts 250,500,2000
./tools/benchmarks/Invoke-AdminBenchmark.ps1 -Pass my-lookup-boundary -Group lookup -LookupCounts 1000,5000 -QueryCounts 2,3,4,10
./tools/benchmarks/Invoke-AdminBenchmark.ps1 -Pass my-process-control -Group process-control
$passes = 'my-admin','my-cache-boundary','my-report-boundary','my-lookup-boundary','my-process-control'
./tools/benchmarks/Measure-AdminBenchmark.ps1 -Pass $passes
./tools/benchmarks/Test-AdminEvidence.ps1 -Pass $passes
./tools/benchmarks/Set-BenchmarkPreview.ps1 -Restore
```

## Retained runs

Initial evidence uses pass2, collections-isolated, set-difference, serialization,
longer-load, driver-host, dashboard-initial, and dashboard-load. An exploratory
million-hash dashboard sample is excluded. Initial collection results were
superseded by collections-isolated. Incomplete first, pass1, and driver discovery
runs are excluded. Source changes and configuration are recorded in the evidence.

Admin evidence uses admin-first, admin-cache-boundary, admin-report-boundary,
admin-lookup-boundary, and admin-process-control. Combined JSON/CSV summaries and
completeness checks are under admin-first. Historical source snapshots describe
the measured code; they are preserved when reporting tools or comments change.
