<!-- Experimental only; not reference material for creating production PSU resources. -->
# Database methodology corrections and SQL Server rerun

The November 8, 2026 SQL Server rerun supports pooling, set-based batching and
smaller responses. Corrected worker warm-up changes the short concurrency results;
the original percentages should not be treated as warmed performance comparisons.
The paired index check supports an advantage for the larger JSON documents, with
no consistent advantage for the smaller shapes. The November 20 repeated passes
ran all three providers with the corrected protocol; they show that one pass per
provider is not enough to separate provider behavior from pass-to-pass drift.

## What changed

All three providers' worker scripts now execute and check ten operations of the
assigned role before signaling readiness. Once every worker is ready, the parent
checks the expected warm-up revision total, resets it to zero, checks the reset,
and only then opens the future-time gate. Each worker records its warm-up count
and role; each burst retains `warmup-reset.json`. The excluded block zero remains
separate from these per-process warm-ups. SQLite endpoint workers use the same
role-specific protocol. SQLite and PostgreSQL were first rerun with these changes
in the November 20 repeated passes.

PostgreSQL and SQL Server scripts now measure indexed and unindexed document
reads as counterbalanced pairs within each block. Odd blocks scan first; even
blocks index first. They use the same connection, query, data and object mapping,
with DDL, statistics updates and ten checked warm-up reads outside each clock.
The indexed reuse case is removed from the earlier shuffled plan, preventing
duplicate observations. Raw samples retain pair order, position and warm-up count.
Other connection modes remain in the shuffled read plan. SQL Server's paired
protocol was first exercised on November 8 and PostgreSQL's on November 20.

## Conditions and preservation

`sqlserver-reviewed` used the same installed SQL Server 2025 Standard Developer
17.0.1000.7, Microsoft.Data.SqlClient 6.1.4, PSU 2026.3.0, workstation and C: disk.
The three shapes, seed 1108, repeated ASCII payloads, SQL/object mapping, encrypted
TCP loopback, durability/isolation defaults, seven measured sequential blocks,
three measured concurrency blocks and 200 operations per worker were retained.
The direct and PSU runtime versions still differ. Existing cache, memory,
compression, remote-host, capacity and crash-durability limitations still apply.

Windows authentication provisioned a separate disposable SQL login,
`par_benchmark_review`: the original `par_benchmark_sql` login remained installed,
but its temporary password had already been removed. Neither existing login nor
server configuration was changed. Direct, endpoint and automation-job probes
confirmed SQL authentication, TCP and `sysadmin=0`. Database ownership is confined
to this pass's dedicated databases; production least-privilege permissions remain
untested. A nonsecret login selector was added beside the existing temporary
password mechanism so the running PSU process used the same login as the driver.

`SqlServerEvidence.json` and `SqlServerWindowsEvidence.json` preserve their
original contents. `database/SqlServerReviewedEvidence.json` holds the new portable
summary. Raw JSONL, workers, paired order, source snapshots, plans, identities,
monitoring, field checks, native checksum backups and SHA256 manifest are under
ignored `tools/output/database/sqlserver-reviewed/`; its sibling evidence ZIP
preserves the completed pass. Temporary PSU registrations were restored and
hash-checked. Both temporary password and login-selector files were removed.
The disposable login and dedicated databases remain installed.

## Before and after

These are medians from separate passes, using the original SQL-login pass
`sqlserver-sql` as the baseline. Times are milliseconds. Except for the last
index rows, the read/write/endpoint comparisons use 10,000 records and 256-character
payloads. Direct reads reuse a connection unless indicated; imports contain 1,000
records and batch writes contain 100. These are descriptive changes, not isolated
effects of fixing the methodology.

| Operation | Original | Corrected | Change |
| --- | ---: | ---: | ---: |
| Keyed row, reused connection | 0.373 | 0.358 | -4.1% |
| Keyed row, fresh unpooled connection | 64.826 | 64.516 | -0.5% |
| Keyed row, pooled connection | 0.434 | 0.450 | +3.7% |
| 500 complete rows | 12.403 | 12.580 | +1.4% |
| 500 Id/Name/Cpu rows | 6.670 | 6.718 | +0.7% |
| Per-row inserts, one commit | 11.036 | 5.331 | -51.7% |
| Per-row inserts, 100 commits | 13.231 | 12.152 | -8.2% |
| One OPENJSON insert request | 1.073 | 1.035 | -3.6% |
| PSU keyed row | 17.459 | 17.543 | +0.5% |
| PSU 500 complete rows | 39.582 | 37.271 | -5.8% |
| PSU 500 Id/Name/Cpu rows | 28.492 | 27.148 | -4.7% |
| Direct per-row import | 87.127 | 133.179 | +52.9% |
| Direct OPENJSON import | 33.032 | 31.695 | -4.0% |
| Job per-row import | 1,746.927 | 1,837.671 | +5.2% |
| Job OPENJSON import | 1,752.643 | 1,734.718 | -1.0% |
| 2,048-character JSON documents, scan | 23.511 | 23.376 | -0.6% |
| 2,048-character JSON documents, indexed | 11.169 | 9.284 | -16.9% |

The untouched per-row batch path became much faster while the direct per-row
import became slower. That variation is evidence against attributing every
before/after difference to the corrections. These passes were sequential and
unpaired, used different disposable logins and had no paired orchestration control.
They do not isolate authentication-helper, runtime, allocation, storage or host
effects. No outliers were removed.

| Direct burst | Original operations/s | Corrected operations/s |
| --- | ---: | ---: |
| One reader | 899.5 | 971.2 |
| Four readers | 3,208.3 | 3,481.8 |
| One writer | 1,578.5 | 1,861.9 |
| Four writers | 4,562.5 | 5,048.7 |
| Three readers and one writer | 3,360.3 | 3,594.7 |

Four writers delivered about 2.71 times one writer's throughput in the corrected
pass, versus 2.89 times in the original. Writers still share the same ten keys;
mixed readers query unchanged records. First single-writer operations fell from
about 13.3–13.7 ms to 1.87–1.99 ms, but remained slower than subsequent operations
at about 0.42–0.44 ms median. Assigned-operation warm-up improves the protocol;
it does not establish perfectly steady-state timing. These short closed-loop
bursts do not establish sustained capacity or endpoint concurrency.

At 10,000/2,048, six of seven pairs favored the index. The median paired saving
was 14.193 ms; one indexed observation took 32.399 ms and lost its pair by
8.892 ms. At 10,000/256, all seven indexed observations lost their pairs, with
a median paired penalty of 0.460 ms. At 1,000/256, four of seven favored the
index and the medians were nearly tied (scan 1.939 ms, indexed 1.918 ms).
The index conclusion depends on this payload, selectivity and returned-object
workload; adding the index does not uniformly improve these small reads.

## Checks and reproduction

All 600 direct reads, 192 writes, 168 endpoint reads, 32 imports and 20 bursts
passed their assertions, including the excluded block-zero samples. The bursts
contained 11,200 operations plus 560 checked per-process warm-up operations.
The validator checked role-specific warm-up/reset evidence and 48 indexed/scan
observations (24 pairs including block zero). Full main-table field checks and
DBCC CHECKDB passed for all three measured databases. Rollback, row locks,
read committed, repeatable read, reopen, checksum backup and actual restore passed.
PSScriptAnalyzer passed all 147 PowerShell files with no diagnostics; the complete
Pester suite passed 419 tests. The sandbox initially blocked Pester's temporary
registry key; the same suite passed in the approved host context. Patch whitespace
checks passed. These repository checks are separate from the live SQL/PSU checks.

Run the existing SQL Server workflow with a new pass and, if needed, a new
`Initialize-SqlServerLogin -Login par_benchmark_<name>`. Retain its temporary
credential files through the preview phase and use process environment variables
for the direct workload. Current help owns the command details. After the full
pass is exported, run `database/Compare-SqlServerEvidence.ps1` (extracted from
the archived harness) to regenerate
all 129 matched summary comparisons and 21 measured index pairs as JSON/CSV
under `tools/output/database/sqlserver-review-comparison/`. This comparison
does not require SQL Server or alter either retained pass.

## November 20 repeated passes

Each provider ran its complete documented workflow at least three times on the
same workstation, with a rest of at least 30 seconds after every pass. SQLite and
SQL Server alternated in each loop; SQL Server was then uninstalled before the
PostgreSQL passes. Run-to-run anomalies were defined before reading results: a
case was flagged when its median changed by more than 25% and the two passes'
min–max ranges did not overlap, ignoring median differences below 0.25 ms. Two
passes were compared first, and a third pass was run when that comparison flagged
cases. Every pass passed its own validator, including role-specific warm-up/reset
checks and, for PostgreSQL, the counterbalanced index pairs.

| Provider | Passes | Flagged: 1 vs 2 | 1 vs 3 | 2 vs 3 |
| --- | --- | ---: | ---: | ---: |
| SQLite | `sqlite-loop1`–`3` | 13 of 96 | 13 of 96 | 0 of 96 |
| SQL Server | `sqlserver-loop1`–`3` | 7 of 129 | 5 of 129 | 0 of 129 |
| PostgreSQL | `postgres-keyorder1`–`3` | 9 of 129 | 0 of 129 | 13 of 129 |

All flagged cases were sequential direct reads or small writes; concurrency
bursts never met the rule. SQLite's first pass was the outlier: reused-connection
row reads at 10,000 records roughly doubled (500 complete rows: 25.42 ms against
11.57 and 11.21 ms). SQL Server's first pass was slower only in 1,000-record row
reads (500-row filter at 1,000 records: 2.72 ms against 1.42 and 1.50 ms). For
PostgreSQL, the second key-order pass was the outlier in the opposite direction:
its 1,000-record reads were faster (filter: 1.12 ms against 1.75 and 1.84 ms). The
1,000-record database is the first shape measured in every pass. These passes do
not identify the cause; host state, caching and the measurement order remain
plausible contributors. Treat a single pass's small-shape read medians as
uncertain by up to about a factor of two.

| Direct burst, operations/s | SQLite (2, 3) | SQL Server (2, 3) | PostgreSQL key order (1–3) |
| --- | ---: | ---: | ---: |
| One writer | 2,018; 1,996 | 2,095; 2,122 | 2,616; 2,368; 2,328 |
| Four writers | 1,427; 1,420 | 5,211; 5,181 | 4,133; 3,719; 3,669 |
| Four readers | 4,495; 4,681 | 3,708; 3,634 | 4,599; 4,373; 3,856 |

### PostgreSQL writer lock order

The first PostgreSQL passes used the original increment, an unordered
`UPDATE ... WHERE Id<=10` on the same ten rows. `postgres-loop1` passed with no
deadlocks. `postgres-loop2` failed its four-writer burst: the server log recorded
45 deadlocks within about a minute, each waiting the default one-second
`deadlock_timeout`, so the workers exceeded the 45-second burst limit. PostgreSQL
locked the rows in physical scan order, which shifts as updates create new row
versions. SQL Server's clustered-key scan locks in key order and did not deadlock.

The increment now locks the ten rows in `Id` order through a `FOR UPDATE`
subquery before updating them, and PostgreSQL metadata records `WriterLockOrder`.
The `postgres-keyorder` passes logged no deadlocks. The extra lock step lowered
one-writer throughput from 3,627 to 2,616 operations/s and four-writer throughput
from 4,819 to 4,133 operations/s between `postgres-loop1` and `postgres-keyorder1`.
Compare PostgreSQL writer bursts only with key-order passes; the historical
`postgres-local` evidence used the unordered statement.

### Conditions and preservation

The SQL Server instance had been updated to 17.0.1155.3 since the November 8
passes. Windows authentication created a new disposable login for each pass
(`par_benchmark_loop1`–`3`); each pass's temporary password and login-selector
files were removed. PostgreSQL 18.6 was a fresh installation using the
owner-designated disposable administrative password; the benchmark created
`par_benchmark` on first use. It listened on all interfaces, although every
benchmark connection used `127.0.0.1`. Each pass temporarily registered and then
restored its PSU preview on the dedicated development instance, with hashes
checked. The `SkipPortable` option of the save scripts kept
the committed portable evidence files unchanged. Raw evidence and comparisons are
in ignored `tools/output/database/`, including `provider-loop-comparison/`, both
loop logs and an evidence ZIP for each SQL Server and PostgreSQL pass. The
orchestration and comparison scripts were session tools and were not retained;
the rule above and the documented workflows reproduce the procedure.
