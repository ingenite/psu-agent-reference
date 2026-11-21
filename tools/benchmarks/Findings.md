<!-- Experimental only; not reference material for creating production PSU resources. -->
# PSU runtime benchmarks

Why this exists: PSU guidance describes cache serialization, job startup and
output costs only in general terms. These measurements show where they matter
for ordinary admin work. Five choices held up:

1. **Cache only the fields readers need.** Whole `Get-Process` objects took
   about 41 ms *each* to serialize, which is enough to matter even for one
   object. Selecting three fields first cut 100 processes from 4.1 s to 6 ms.
   For synthetic directory users, selecting before caching paid off from about
   ten records, and saved about 100 ms per write/read cycle at 1,000 users.
2. **Use jobs for their lifecycle, not their speed.** A job adds about 1.5 s of
   startup. Under four concurrent callers, though, endpoint computation slowed
   about 3× while jobs barely changed, so long concurrent work finished sooner
   as jobs.
3. **Suppress unwanted output where it is created.** Assigning 5,000 strings
   to `$null` saved about 1 s and 1.4 MB per job. `DiscardPipeline` dropped the
   stored payload but kept the job messages, so it saved little time.
4. **Capture loop output instead of using `+=`.** At 10,000 rows, capture took
   21 ms against 76 ms and allocated 22 MB against 422 MB. The difference is
   negligible below a few hundred rows, but capture is just as readable, so use
   it by default.
5. **Build a hashtable index only when lookups repeat.** Ten lookups always
   repaid the build cost; one lookup over 5,000 users favored a plain `foreach`
   scan. `Where-Object` was slowest in every case. Generic collections gave no
   general benefit; the exception was a bulk `HashSet.ExceptWith`.

| Example | Simple choice (ms) | Better choice (ms) |
| --- | ---: | ---: |
| Cache 100 whole processes vs three selected fields | 4,100.7 | 6.1 |
| Cache 1,000 directory users, 39 vs 4 fields | 126.8 | 23.3 |
| Job emitting 5,000 strings vs suppressed | 2,603 | 1,566 |
| Build 10,000 report rows, `+=` vs capture | 75.9 | 20.8 |
| 20 lookups over 5,000 users, scan vs hashtable | 5.39 | 0.68 |

## Method

- Dedicated PSU 2026.3.0 instance (PowerShell 7.6.5, SQLite) on one Ryzen 5
  9600X workstation; the harness ran PowerShell 7.6.9.
- Cache tests used `Set-PSUCache -Persist` and `Get-PSUCache` through an
  authenticated endpoint. Reads were warm and followed writes.
- Hash work (SHA-256 over 4 KB) ran as an endpoint, a job and an inline
  dashboard callback, with one and four callers.
- Process inputs were real local `Get-Process` objects. Directory users were
  synthetic objects with 39 properties; no Active Directory was queried.
- Cases ran in shuffled order after a warm-up, with five or seven measured
  samples. Each variant produced the same checked result; checks ran outside
  the timers. "Always" means all seven pairs.

## Limits and evidence

Results describe one shared workstation and small warm workloads, not capacity
or universal thresholds. Retest when the output, object types, reuse or runtime
change. Open questions are recorded in `docs/errata.md`. Raw samples and pass
plans stayed in ignored `tools/output/benchmarks/`; `README.md` shows how to
reproduce them.
