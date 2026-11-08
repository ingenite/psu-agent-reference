<!-- Experimental only; not reference material for creating production PSU resources. -->
# Common admin tasks: when does extra work pay off?

The answer depends on the objects and what the reader needs. These tests compare
the same useful results, including the cost of selecting fields, filtering rows,
building an index, or converting a list back to an array.

| Choice | What the measurements support |
| --- | --- |
| Select process fields before caching | Saved about 43 ms even for one process. Whole process objects were expensive to serialize. |
| Select/filter directory-user rows before caching | A transition around 5–10 records; consistent gains across tested views at 10. At 1,000, saved about 96–102 ms per write/read cycle. |
| Capture report rows instead of repeated array += | Consistently faster at 500 rows, but saved only 0.08 ms. Savings reached about 1 ms at 2,000 rows and 55 ms at 10,000. |
| Build a hashtable for account lookups | Mixed results at a few lookups; ten consistently repaid the build cost over 1,000–5,000 users. One lookup over 5,000 favored a simple scan. |
| Replace native collections with generic types | No general benefit here. The bulk HashSet operation in Findings.md is a separate useful case. |

“Consistent” means faster in all seven measured pairs. It is not a probability or
a promise for another machine. Small differences rarely justify extra complexity.

## What was compared

Tests used the same PSU 2026.3.0, PowerShell 7.6.5, SQLite, and workstation as the
initial results. Each pair shared one input. Case and variant order were shuffled,
with one warm-up and seven measured samples per case. Focused follow-ups brought
the total to 76 cases and 608 samples, including warm-ups.

Process inputs were actual local `Get-Process` objects, sorted by Id. Directory
inputs were synthetic objects with 39 properties, including group memberships,
proxy addresses, and extension attributes. Every fifth user, including the first,
was enabled. No Active Directory module, domain, or tenant was used. These are not
measurements of `Get-ADUser`, ADUser objects, or network queries.

Input acquisition was recorded separately. Timed work included all steps needed
to produce the useful output. Equality checks, database inspection, and cleanup
were outside those timers. Cache reads immediately followed writes to new keys;
these are warm reads, not refresh or restart tests.

## Process inventory: select the fields the table needs

The table needed only Id, ProcessName, and SessionId. One variant cached complete
process objects and selected those fields after reading. The other selected them
before caching. Both used serialization depth 1 and returned the same table.

| Processes | Whole objects: write + read median ms | Select first: median ms | Whole / selected XML bytes |
| ---: | ---: | ---: | ---: |
| 1 | 46.07 | 3.65 | 13,258 / 620 |
| 10 | 304.70 | 3.85 | 69,646 / 2,503 |
| 50 | 2,368.80 | 4.45 | 479,860 / 10,988 |
| 100 | 4,100.70 | 6.09 | 943,873 / 21,630 |

All seven pairs favored selection at every count. One process saved 41.86–46.75 ms.
At 100, whole-object cycles ranged from 3.96–5.15 seconds; selected cycles were
4.95–10.44 ms.

To investigate the large difference, a control serialized objects without database
calls. One whole process took about 41 ms, versus 0.08 ms including selection for
the three-field object. Much of the cost was already present before storage.
Installed type data showed getters that read executable version information;
avoiding them is a plausible explanation, but each getter's cost was not isolated.

Selecting first paid off immediately for this table. Different fields or process
types can change the result. A dashboard needing CPU or working-set values has a
different contract; omitting needed data would not be an equivalent optimization.

## Directory table: select once rather than after every read

The useful fields were SamAccountName, DisplayName, Mail, and Department. Tests
compared caching all 39 fields against selecting four first, with either all users
or only enabled users. Both used depth 3.

| Users, all rows, one read | Broad cache cycle median ms | Select first median ms | Paired savings median ms |
| ---: | ---: | ---: | ---: |
| 1 | 3.07 | 3.14 | -0.22 |
| 5 | 3.92 | 3.01 | 0.88 |
| 10 | 4.03 | 3.27 | 1.03 |
| 100 | 12.03 | 5.06 | 6.98 |
| 1,000 | 126.78 | 23.28 | 102.34 |

Savings are calculated within each pair, so they need not equal the difference
between the two column medians. Results at 1–4 users varied; the enabled-only
five-user case won five of seven pairs. Ten was the first tested count where both
views won every pair with either one or five reads. This brackets a useful range,
not an exact cutoff.

At 1,000 users, selecting four fields reduced XML from 4.36 MB to 0.29 MB.
Selecting only the 200 enabled users reduced it to 0.059 MB and saved about 96 ms.
With five reads, selecting once saved about 277–290 ms. Reuse made the gain larger.

For real AD queries, `Get-ADUser` has source filter and property options described
in the [command reference](https://learn.microsoft.com/powershell/module/activedirectory/get-aduser).
Those query costs were not tested. Keep fields and users needed by other cache
consumers; changing their useful result changes the comparison.

## Report rows: array capture is a simple default

Each variant built the same four-field report objects. List timings include
conversion to an object array.

| Rows | Array += median ms | Array capture median ms | List median ms | Paired capture savings median ms |
| ---: | ---: | ---: | ---: | ---: |
| 100 | 0.19 | 0.19 | 0.92 | 0.01 |
| 500 | 0.95 | 0.89 | 4.50 | 0.08 |
| 2,000 | 5.10 | 4.02 | 18.44 | 1.09 |
| 5,000 | 17.23 | 10.11 | 45.29 | 6.92 |
| 10,000 | 75.89 | 20.82 | 91.29 | 55.19 |

At 500 rows, savings ranged from 0.02–0.19 ms. At 10,000 they ranged from
4.12–94.98 ms, and array capture allocated about 22 MB versus 422 MB for `+=`.
These are allocated bytes, not memory kept after the operation.

Use `$rows = @(foreach ($user in $users) { ... })` when it is readable. There is no
reason to wait for 500 rows; that count describes when the timing difference became
consistent here. A few occasional appends were not shown to cause a useful delay.
The list did not beat capture at any tested report size.

## Account lookups: build an index when it will be reused

All queries matched unique accounts near the middle of a preloaded collection.
Uppercase queries checked ASCII case-insensitive matching. Each variant returned
the same email sequence. Hashtable timings include building the index each time.

| Users / lookups | Foreach scan median ms | Hashtable median ms | Where-Object median ms |
| --- | ---: | ---: | ---: |
| 1,000 / 1 | 0.16 | 0.14 | 1.50 |
| 1,000 / 10 | 0.61 | 0.13 | 14.40 |
| 5,000 / 1 | 0.26 | 0.72 | 7.50 |
| 5,000 / 10 | 2.64 | 0.79 | 94.50 |
| 5,000 / 20 | 5.39 | 0.68 | 175.84 |

A hashtable beat `Where-Object` even for one lookup. Compared with a foreach scan
that stops at the match, 2–5 lookups were mixed. Ten lookups won every pair, saving
0.47–0.65 ms over 1,000 users and 1.67–3.75 ms over 5,000. This supports reusing an
index for repeated lookups, without an exact fourth- or fifth-lookup rule.

Misses, duplicate names, Unicode matching, and keeping an index across refreshes
were not tested. Generic dictionaries offered no stable practical improvement.

## Evidence and stopping point

README.md lists the five pass plans and reproduction commands. Raw samples,
source snapshots, paired summaries, and checks are retained under
`tools/output/benchmarks/`. All equality checks passed, temporary admin cache keys
were removed, and original development registrations were restored and hash-checked.

The follow-ups resolved useful ranges and investigated the expensive process writes.
More small-count tuning would mostly chase fractions of a millisecond. Retest when
the useful output, object types, reuse, runtime, or source system changes.
