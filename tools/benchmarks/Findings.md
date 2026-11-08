<!-- Experimental only; not reference material for creating production PSU resources. -->
# PSU benchmark results — November 7, 2026

These tests support four useful choices: cache the fields consumers need, use jobs
when their extra startup cost is worthwhile, suppress unwanted output where it is
created, and measure before replacing ordinary PowerShell collections.
[Admin scenarios](AdminScenarios.md) puts these choices into process inventories,
directory-user tables, report building, and account lookups.

## Conditions and expectations

Tests ran on the dedicated PSU 2026.3.0 instance with PowerShell 7.6.5, .NET 10.0.12,
and SQLite. The harness used PowerShell 7.6.9. The workstation had a Ryzen 5 9600X
(6 cores, 12 threads), about 32 GiB RAM, Windows build 26200, and the High performance
power plan. PSU used Information logging, Strict API security, 20 job workers,
25 maximum runspaces, and no persistent runspaces. This was a shared workstation.

[PSU guidance](https://docs.devolutions.net/powershell-universal/config/best-practices)
describes cache serialization costs, job startup, and the storage saved by discarding
pipeline output. [Microsoft guidance](https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/performance/script-authoring-considerations)
discusses collection choices and version-dependent array behavior. These explain
what to expect; the numbers below are measurements from this host.

Cases used shuffled order and a separate warm-up. Initial results use five measured
repetitions; collection follow-ups use seven. Ranges show observed minimum–maximum,
not a guarantee of accuracy on another host. Checks outside the workload timers
verified cache values, hashes, output strings, and collection results.

## Persistent cache: smaller useful values cost less

These calls used `Set-PSUCache -Persist -Depth 20` and `Get-PSUCache`, through an
authenticated Integrated endpoint. They did not use `$Cache:`. Each record had an
Id plus the stated number of properties. Values contained identifiers and the
stated number of characters; nesting added two Child objects around each value.

| Records / properties / nesting / value characters | Stored XML bytes | Set median ms | Read all median ms (range) |
| --- | ---: | ---: | ---: |
| 100 / 4 / 0 / 32 | 39,103 | 3.07 | 2.22 (1.98–2.40) |
| 1,000 / 4 / 0 / 32 | 393,704 | 8.25 | 5.13 (4.58–10.03) |
| 1,000 / 16 / 0 / 32 | 1,196,384 | 25.29 | 12.53 (10.85–25.77) |
| 1,000 / 4 / 2 / 32 | 1,529,704 | 44.05 | 20.76 (16.28–63.42) |
| 1,000 / 4 / 0 / 1,024 | 4,361,704 | 39.86 | 54.56 (37.55–60.89) |

More records, fields, nesting, and larger values increased storage and read costs,
as expected. These changes also change byte size, so the test does not separate
the cost of shape from the cost of size.

Splitting the largest case into ten keys of 100 records gave an all-read median
of 58.23 ms rather than 54.56 ms, with overlapping ranges. Reading one needed partition
took 4.56 ms; reading the full value again took 41.70 ms. Partition by what readers
need, rather than expecting every read to improve.

Reads followed writes and were warm. Sizes count the stored value, excluding
database pages, indexes, and journal files. The largest value was about 4.2 MiB;
no maximum size or cold-disk behavior was established. XML storage and complete
round trips were verified. Restart survival was not: Windows denied the attempted
development-server stop, and no server stopped. The database's `Persistent` flag
was 0 despite `-Persist`; its meaning remains unresolved.

## Execution location: jobs add startup cost, but load changes the comparison

Each iteration hashed the same prepared 4,096 bytes with SHA-256. Only the final
digest was returned. All locations produced the independently checked digest.

| 100,000 hashes, one caller | Computation median ms (range) | Completion median ms |
| --- | ---: | ---: |
| Endpoint | 534 (478–588) | 552 |
| Automation job | 520 (518–524) | 1,984 |
| Inline dashboard callback | 496 (487–499) | 519 |

Computation was similar. Jobs added about 1.5 seconds, consistent with their fresh
processes. Endpoint and app processes were reused. Endpoint completion means an
HTTP round trip; job completion includes submission, startup, storage, and observing
the finished job, with 50 ms polling. Dashboard completion means backend HTTP handling from
PSU logs; browser rendering was not measured.

Four concurrent requests slowed computation in endpoints and callbacks much more
than in jobs. Longer runs and a second HTTP driver reproduced the endpoint effect.
The longer test used one million hashes per request, with three measured bursts
after warm-up for each row below:

| Location / callers | Computation median ms (range) | Completed request median ms | Observed driver-cycle requests/sec |
| --- | ---: | ---: | ---: |
| Endpoint / 1 | 4,735 (4,710–4,747) | 4,749 | 0.210 |
| Endpoint / 4 | 14,524 (14,211–14,730) | 14,611 | 0.271 |
| Job / 1 | 4,827 (4,810–4,828) | 6,305 | 0.158 |
| Job / 4 | 5,702 (5,459–5,886) | 8,639 | 0.451 |

The last column divides requests by the whole driver cycle. It includes dispatch
and, for jobs, reading the diagnostic file and downloading saved output after
completion was observed. Output downloads averaged about 13–16 ms here. This is
not an equal-boundary server throughput measurement. Each burst counts once;
its four request times are correlated. The summary uses the maximum saved wall
time per burst because older passes sampled that clock while writing rows.

Short synchronous work had lower latency in endpoints and callbacks. Jobs completed
these longer four-request bursts faster, even with their extra collection work.
The dashboard load test ran separately, so it supports the slowdown observation
rather than an exact ranking across all three locations. Neither the cause of the
slowdown nor sustained production capacity was established.

## Unwanted output: suppressing it saved time and storage

Each job prepared the same 5,000 strings, then emitted them, used `DiscardPipeline`,
or assigned each value to `$null`. Stored strings and job messages were checked.

| Choice | Output-loop median ms | Completed job median ms (range) | Saved pipeline bytes | Job message bytes / rows |
| --- | ---: | ---: | ---: | ---: |
| Emit | 928 | 2,603 (2,437–2,665) | 723,977 | 688,890 / 5,000 |
| DiscardPipeline | 879 | 2,430 (2,373–2,714) | 0 | 688,890 / 5,000 |
| Suppress at source | 3.42 | 1,566 (1,460–1,577) | 0 | 0 / 0 |

Suppression saved about one second and 1.41 MB of logical payload per job.
DiscardPipeline saved the pipeline payload but kept the logs; its completion
ranges overlapped emission. At 100 strings, startup variability hid any useful
completion-time improvement.

A separate serialization control took about 4 ms to serialize and 20 ms to read
the 5,000 strings back. This suggests delivery, logging, and per-item handling
contribute substantially to the output cost. It does not isolate their individual
costs. Database growth over time and complex output objects were not tested.

## Collections: ordinary PowerShell remained useful

These comparisons include creating the collection. Result checks were outside
timing. Allocated bytes count work on the measured thread, not retained memory.

| 10,000-item operation | Median ms (range) | Allocated MB |
| --- | ---: | ---: |
| Repeated array += | 17.00 (16.33–34.34) | 400.5 |
| Capture loop output in an array | 0.25 (0.22–0.31) | 0.59 |
| List[int] with repeated Add | 70.45 (67.59–74.07) | 6.04 |
| Hashtable build and key lookup | 2.11 (1.96–5.84) | 3.35 |
| Dictionary build and key lookup | 1.73 (1.60–2.72) | 3.97 |
| Repeated array membership scans | 322.85 (321.75–327.24) | 1.47 |
| Hashtable build and membership checks | 23.00 (22.76–25.35) | 5.35 |
| HashSet with per-item Add/Contains | 133.99 (132.14–138.06) | 13.3 |

Capturing loop output was a good construction choice. A hashtable helped repeated
lookups; generic types did not offer a general improvement. Moving loops into small
scriptblocks preserved these results. Despite version-dependent guidance about
array addition, this repeated `+=` pattern still allocated heavily on 7.6.5;
the host probe on 7.6.9 showed the same pattern. No version comparison was established.

A bulk generic operation did help: removing 5,000 even numbers from 10,000 integers
with a HashSet constructor and `ExceptWith` took 0.24 ms (0.22–1.52), versus
22.94 ms (22.63–31.72) for hashtable construction and filtering. Both included
construction and returned the same members; order did not matter. Typed inputs
and set semantics make this a specific useful case, not a reason for broad rewrites.

## Evidence and stopping point

Raw samples, configuration, source snapshots, checks, and pass names are retained
under `tools/output/benchmarks/`; README.md explains reproduction. Incomplete
discovery passes are excluded. Useful findings are established; more repetitions
are unlikely to change these choices. Restart durability and the cause of contention
would need different tests.

The original development registrations were restored and hash-checked. Benchmark
assertions and the 408 repository tests passed; static analysis and whitespace
checks passed. These checks do not establish live external-system behavior.
