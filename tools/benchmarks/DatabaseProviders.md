<!-- Experimental only; not reference material for creating production PSU resources. -->
# Database providers: SQLite, PostgreSQL and SQL Server

SQLite suits a small PSU application on one host with short, batched writes.
PostgreSQL and SQL Server add a service and independent-row writes. All three
passed November 8, 2026 synthetic checks on the same workstation and disk.
For this small local application, connection handling, batching and response size
usually matter more than the provider's read-time differences.

The tables below preserve the initial provider passes. An independent review
found missing writer warm-up and a fixed-order index comparison; see the
[corrections and SQL Server rerun](DatabaseReview.md) for the corrected protocol,
new SQL Server evidence and comparison. The same document records the
November 20 repeated passes of all three providers with the corrections,
including a PostgreSQL writer lock-order change.

| Provider | Evidence here | Practical fit and operating cost |
| --- | --- | --- |
| SQLite | Direct, PSU, concurrency and operating checks passed. | Local storage without another service; manage driver dependencies, file permissions, backups and writer contention. |
| SQL Server 2025 Standard Developer | Direct, selected PSU, concurrency and operating checks passed. | Useful where Windows authentication and SQL Server skills/tooling fit; manage a service, permissions, memory, recovery/log backups and maintenance. Developer edition is for development/testing. |
| PostgreSQL | Direct, selected PSU, concurrency and operating checks passed. | Manage a service, TCP/authentication, credentials, pooling, backups, vacuuming and upgrades. |

## What changes an administrator's decision

Median complete reads over 10,000 records with 256-character payloads:
direct PowerShell reuses a connection; PSU includes HTTP transfer and JSON parsing.

Each cell is **direct / PSU**, in milliseconds.

| Useful result | SQLite | PostgreSQL | SQL Server |
| --- | ---: | ---: | ---: |
| One keyed row | 0.34 / 18.8 | 0.44 / 16.3 | 0.37 / 17.5 |
| 500 complete rows | 13.5 / 42.3 | 9.4 / 36.4 | 12.4 / 39.6 |
| The same rows, only Id/Name/Cpu | 7.0 / 27.5 | 5.0 / 24.4 | 6.7 / 28.5 |

These are complete client operations in separate passes. PostgreSQL and SQL Server
PSU connections were pooled; SQLite's were not. Fresh unpooled keyed reads took
**0.77 / 17.7 / 64.8 ms** for SQLite/PostgreSQL/SQL Server; pooled server reads took
**0.40 / 0.43 ms**. Both server providers used database passwords. SQL Server 2025's
documented PBKDF2 login cost is consistent with its fresh-connection result; hashing
was not timed separately. Its earlier Windows-authenticated pass took **2.69 ms**
unpooled. Pooling removes the large recurring login cost. SQL Server retained
encrypted TCP; PostgreSQL used SSL disabled. These remain different connection costs.

For 100 inserts, SQLite took **1.30 ms** with one commit versus **33.8 ms** with
100 commits. PostgreSQL took **3.84 ms** versus **6.97 ms** with per-row requests,
or **1.74 ms** sending the batch in one request. SQL Server took **11.0 / 13.2 ms**
with one/100 commits, or **1.07 ms** for one `OPENJSON` request.
Batch both commits and server requests.

At 2,048 payload characters, initial scan/index medians for a 500-document read
were 38.4 / 11.3 ms for SQLite,
14.2 / 9.5 ms for PostgreSQL JSONB and 23.5 / 11.2 ms for SQL Server JSON text.
The PostgreSQL and SQL Server observations came from separate fixed-order phases;
they do not isolate the exact index gain. Projection reduced each PSU response
from about **1.08 MB to 23 KB**. Choose a readable model and suitable indexes.

Initial direct reader bursts observed 3.5 / 3.1 / 3.6 times one reader's throughput for
SQLite/PostgreSQL/SQL Server. Four writers sharing ten keys changed throughput
by -21% / +74% / +189%. These historical writer results include first-use costs:
every new process warmed only the read path, including writers. They should not
be treated as warmed scaling comparisons. The corrected SQL Server pass is
reported separately. Both server providers allowed an independent-row write
while a conflicting write timed out. These bursts do not establish capacity;
PostgreSQL and SQL Server endpoint concurrency was not repeated.

All required driver loading and explicit SQL/object mapping. PostgreSQL also
needed login/database setup, credentials, pooling and integer parameter mapping.
SQL Server needed TCP and mixed-authentication setup/restarts, typed parameters,
a login and database permissions. The measured SQL login owned only its benchmark
databases and had no server administrative role. Windows authentication also worked;
its earlier pass used administrative access. Production permissions remain untested.
A 1,000-row import took
28 ms directly / 1.56 s as a job for SQLite, and 39 ms / 1.67 s for PostgreSQL's
recordset method (64 ms / 1.75 s per-row). SQL Server's `OPENJSON` import took
33 ms / 1.75 s (87 ms / 1.75 s per-row). Choose jobs for lifecycle/history benefits.

SQLite's held writer timed out and a long reader delayed checkpoint progress.
PostgreSQL's default read-committed transaction saw newly committed changes;
repeatable read retained its snapshot. SQL Server's default read committed also saw
new commits, but repeatable read held shared locks and blocked a competing writer;
its snapshot modes were disabled. All passed rollback, backup and reopen;
PostgreSQL passed logical restore/relation checks, SQL Server checksum backup,
actual restore and `DBCC CHECKDB`. Crash durability,
remote access, production permissions and frontend behavior remain untested.
Warm small tables, compressible payloads and a shared workstation limit these timings.

For more details on the test parameters or methodology, direct your AI of choice to [Test context and evidence](#test-context-and-evidence).

## Test context and evidence

- **Conditions:** Windows 11 build 26200; Ryzen 5 9600X, 6 cores/12 threads;
  31.6 GiB RAM; all files on C:, WD_BLACK SN850X NVMe disk 1; High performance
  plan. During the SQLite pass no SQL Server/PostgreSQL services were found or started. SQLite 3.53.3
  through the existing Microsoft.Data.Sqlite 10.0.10 driver and SQLitePCLRaw
  dependencies. The other bundled driver, System.Data.SQLite 1.0.115.5 / SQLite
  3.37.0, lacked `json_extract`. No software was installed for that pass.
  PSU integration also required its configured script-base path and one JSON
  string to preserve the import metrics through saved job output.
- **Resource/durability settings:** WAL, `synchronous=FULL`, 4,096-byte pages,
  8 MiB private cache per connection, 1,000-page automatic checkpoint, foreign
  keys enabled; no pooling; five-second provider timeout. PSU 2026.3.0 used
  Integrated authenticated endpoints, 25 maximum environment runspaces,
  persistent runspaces disabled, Information system logging and Strict API
  security. The API reported a 1,000 concurrent-job limit and no configured
  job-memory limit; active job-worker count was not established. Harness
  PowerShell 7.6.9/.NET runtime configuration 10.0.14 differs from PSU's
  PowerShell 7.6.5/runtime configuration 10.0.12.
- **Plan:** seed 1108; 1,000/256, 10,000/256 and 10,000/2,048 record/payload shapes.
  Fixtures and document JSON are prepared outside database timers. Seven shuffled
  blocks follow one warm-up. Reads cover keys, filters and equivalent offset/seek
  pages; no useful paging winner emerged at this size. Writes cover 100-row
  batches and revision refreshes; the work tables do not maintain the main
  JSON expression index. Endpoint projection ran separately, so that latency
  comparison is not paired. Concurrency uses one/four readers, one/four writers,
  and three readers plus one writer: 200 operations per warmed, gated process,
  one warm-up and three measured bursts. Mixed readers query unchanged records
  in the same file; writers share ten keys. No application retry is added.
- **Boundaries and controls:** direct client timers include helper call/return,
  SQL stepping and building objects; `ExecuteReaderMs` alone is not engine time. Serialization
  is separate for direct reads. HTTP clients include JSON parsing; job clients
  include submission, 50 ms completion polling and result retrieval. Sizes are
  response-body bytes; headers/compression were not separately audited. Burst wall
  time counts once, including between-operation driver work. Windows counters
  and process CPU/memory are sampled once per second, too slowly to attribute
  individual direct bursts. The small background read/JSON control added
  0.6–2.6% to three paired blocks; it does not model every agent/tool operation.
- **Artifacts:** `database/SqliteEvidence.json` is the portable structured
  summary, including distributions, operating checks, resource observations and
  limitations. Full raw evidence is under ignored
  `tools/output/database/sqlite-local/`, with `summary.json`, JSONL samples,
  per-worker samples, query plans, monitoring and historical source snapshots.
  Its sibling `sqlite-local-evidence.zip` retains the complete pass. Initial
  `sqlite-main` and smoke/discovery runs are excluded. Sequential direct totals
  use `client-boundary/`; earlier inner-clock samples remain stage evidence. Field equality, final
  increments, counts, backup contents and all 22,400 concurrent operations
  (including warm-ups) were checked. Both preview registrations were restored
  and hash-verified. Some original metadata projections were empty; supplemental
  condition files correct those gaps without changing samples.

The harness scripts are archived and unmaintained; they are not analyzed, tested
or reviewed as repository source. Extract them in place before reproducing any
pass below; extracted scripts are ignored by Git:

```powershell
Expand-Archive -LiteralPath ./tools/benchmarks/database/DatabaseHarness.zip -DestinationPath ./tools/benchmarks/database
```

Reproduce from the repository root in PowerShell 7, with the existing bundled
drivers and designated development API token available. Windows diagnostic access
is required. These commands create new files; preview setup changes only the
dedicated development instance. Command help owns detailed contracts.

```powershell
$pass = 'my-sqlite'
./tools/benchmarks/database/Invoke-SqliteBenchmark.ps1 -Pass $pass
./tools/benchmarks/database/Get-SqliteCondition.ps1 -Pass $pass
./tools/benchmarks/database/Measure-SqliteBoundary.ps1 -Pass $pass
./tools/benchmarks/database/Set-SqlitePreview.ps1 -Pass $pass
try {
    ./tools/benchmarks/database/Invoke-SqliteFollowup.ps1 -Pass $pass
    ./tools/benchmarks/database/Invoke-SqliteProjection.ps1 -Pass $pass
    ./tools/benchmarks/database/Test-SqliteOperation.ps1 -Pass $pass
} finally {
    ./tools/benchmarks/database/Set-SqlitePreview.ps1 -Pass $pass -Restore
}
./tools/benchmarks/database/Test-SqliteEvidence.ps1 -Pass $pass
./tools/benchmarks/database/Measure-SqliteBenchmark.ps1 -Pass $pass
./tools/benchmarks/database/Export-SqliteEvidence.ps1 -Pass $pass
```

### PostgreSQL conditions and retained pass

- **Installation and access:** the owner's temporary native Windows installation
  reported PostgreSQL 18.6, x64/MSVC. Its installation summary named `postgres` as
  superuser; a TCP query of `current_user` and `pg_roles` confirmed it. `sa` was
  not assumed. Service `postgresql-x64-18` ran as NetworkService. Data and WAL
  were under `C:\Program Files\PostgreSQL\18\data`, on the same C: disk as SQLite.
  Every connection used `127.0.0.1:5432`, password/SCRAM authentication and SSL
  disabled. The installer listened on `*`; no remote connection was tested.
  No PostgreSQL tuning, restart or durability relaxation was needed.
- **Database and driver:** created non-superuser `par_benchmark` and dedicated
  `par_pg_postgres_local_*` databases; no PSU internal database was changed.
  Used existing bundled Npgsql 10.0.3 plus its logging abstraction, with no new
  driver installation. `server-before.json` records conditions before measurement;
  each shape retains effective session settings, plans with execution/buffer data,
  identity and relation sizes. Source snapshots retain the code actually measured.
- **Effective settings:** 128 MiB shared buffers, 4 MiB work memory, 64 MiB
  maintenance memory, 4 GiB effective-cache estimate (not an allocation),
  100 connections, 8 maximum parallel workers / 2 per gather. `fsync=on`,
  `synchronous_commit=on`, `full_page_writes=on`, checksums on, `wal_level=replica`,
  `wal_sync_method=open_datasync`, 4 MiB WAL buffers, 1 GiB maximum WAL,
  five-minute checkpoints, autovacuum on with three workers. Tables are logged;
  ordinary defaults and OS cache differ from SQLite's per-connection cache.
- **Equivalent work and differences:** reused identical seed-1108 fixtures and
  field equality checks at all three shapes. Eight read cases run in shuffled
  reuse/new/pooled order for seven measured blocks after a warm-up. A separately
  warmed no-expression-index JSONB phase supplies the scan comparison; its plan
  is retained. Offset and seek pages return equivalent records. PostgreSQL uses
  JSONB and a B-tree expression index, rather than SQLite JSON text; field equality
  is checked instead of property order. PostgreSQL TOAST/pglz can compress these
  repeated `x` payloads unusually well. Relation sizes are not production estimates.
- **Write choices:** 100-row per-row prepared statements retain the SQLite
  transaction/autocommit foundation. Set variants send one JSONB recordset for
  inserts or one integer key array for updates. Batch JSON is prepared outside
  database timers. Work tables have primary keys without the main filter index.
  Selected Integrated endpoint reads use pooling; import automation measures
  both per-row and single-request methods. Import fixture decoding and recordset
  JSON preparation are inside the whole-script/client boundary. Explicit int4
  casts fixed the JSON integer mapping discovered during the initial import pass.
- **Boundaries and PSU:** direct outer `Measure-Command` clocks end at helper
  return/usable objects and include owned connection disposal. Serialization
  follows the clock. SQLite used an explicit Stopwatch; neither measures engine
  time alone. HTTP includes JSON parsing; jobs include submission, 50 ms polling
  and pipeline retrieval. PSU 2026.3.0, its Integrated and PowerShell 7 environments,
  resource/security settings and runtime versions are retained with the pass.
  A temporary demonstration password file supplied the two preview resources;
  it was removed after both original registrations were restored and hash-checked.
- **Concurrency and operations:** matching one/four-reader, one/four-writer and
  three-reader/one-writer direct scenarios use 200 operations per warmed gated
  process, one warm-up and three measured bursts. Writers contend on the same
  ten keys; readers query unchanged records. No retries. Each burst wall interval
  counts once, including between-operation driver work. Every operation's size,
  all 11,200 operations including warm-ups, and final fields/increments were
  checked. Independent versus conflicting row locks, read committed versus
  repeatable read, rollback, diagnostic dump/restore and reconnect checks passed.
  `pg_amcheck` checked heap/B-tree/TOAST relations on original and restored diagnostic
  databases. This is logical backup validation, not physical/PITR or crash recovery.
- **Limits and stopping point:** separate warm local passes are not paired
  provider trials. One-second host/process observations include PostgreSQL but
  cannot attribute individual requests; shared working sets can double-count
  memory. Agent/tool activity was not isolated or given a paired PostgreSQL control.
  No additional workload tuning, PostgreSQL endpoint concurrency, sustained load,
  or remote-host tests were needed for that provider phase's bounded choices.
- **Artifacts:** portable `database/PostgresEvidence.json` contains distributions,
  conditions, operational results, resource observations and limitations.
  Ignored `tools/output/database/postgres-local/` retains JSONL samples, per-worker
  samples, plans, monitoring, validation, source snapshots and an SHA256 manifest.
  `retained/` holds custom dumps and SQL schemas of all three measured databases;
  `operations/backup.dump` was actually restored and checked. The sibling
  `postgres-local-evidence.zip` and its checksum preserve the pass independently
  of uninstalling PostgreSQL. Smoke and incomplete `followup-initial` evidence
  are retained but excluded. The temporary installation remains installed;
  neither uninstall nor Git publication is part of this phase.

Reproduce with native PostgreSQL 18 tools, the existing dev-psu Npgsql bundle and
the designated management token. Discover the installation's administrative role
first; `postgres` below is the role verified here. Supply the demonstration
password through the process environment. These commands create new databases
and evidence and temporarily change only the dedicated PSU preview registrations.
`Save-PostgresEvidence` validates, exports and packages the completed pass.

```powershell
$pass = 'my-postgres'
$adminRole = 'postgres'
$env:PGPASSWORD = Read-Host 'Disposable PostgreSQL demonstration password' -MaskInput
try {
    ./tools/benchmarks/database/Get-PostgresCondition.ps1 -Pass $pass -AdministrativeRole $adminRole
    ./tools/benchmarks/database/Invoke-PostgresBenchmark.ps1 -Pass $pass -AdministrativeRole $adminRole
    ./tools/benchmarks/database/Set-PostgresPreview.ps1 -Pass $pass
    try {
        ./tools/benchmarks/database/Invoke-PostgresFollowup.ps1 -Pass $pass
    } finally {
        ./tools/benchmarks/database/Set-PostgresPreview.ps1 -Pass $pass -Restore
    }
    ./tools/benchmarks/database/Invoke-PostgresConcurrency.ps1 -Pass $pass
    ./tools/benchmarks/database/Test-PostgresOperation.ps1 -Pass $pass -AdministrativeRole $adminRole
    ./tools/benchmarks/database/Save-PostgresEvidence.ps1 -Pass $pass
} finally {
    Remove-Item Env:/PGPASSWORD
}
```

### SQL Server conditions and retained pass

- **Installation and transport:** native Windows SQL Server 2025 RTM,
  `17.0.1000.7`, Standard Developer Edition (64-bit), default instance
  `MSSQLSERVER`, service identity `NT Service\MSSQLSERVER`. TCP was disabled after
  installation. Saved its original settings, enabled only `127.0.0.1:1433` and
  restarted this service with Windows elevation. The initial Windows pass used
  NTLM; the owner-requested follow-up enabled mixed authentication and restarted
  this service again. `sa` stayed disabled. No firewall changes or software
  installation. Every measured connection explicitly used `tcp:127.0.0.1,1433`.
  Workload identity probes confirmed SQL authentication over TCP for the follow-up;
  administrative condition discovery still used NTLM. Encryption was unchanged.
  `Encrypt=True;TrustServerCertificate=True` trusts the local certificate without
  validating it. No remote-host or production certificate behavior was tested.
- **Driver and identities:** existing bundled Microsoft.Data.SqlClient **6.1.4**
  (file `6.14.26015.4`, assembly `6.0.0.0`), with no package installation.
  Main comparison numbers now use `sqlserver-sql`: disposable local SQL login
  `par_benchmark_sql`, no server role, `sysadmin=0`, `db_owner` only in dedicated
  `par_sql_sqlserver_sql_*` databases. This resembles the PostgreSQL test role's
  database ownership, not a production permission design. Direct, endpoint and
  automation-job probes independently returned the actual SQL identity; probes
  ran outside measured blocks. Provisioning, backup/restore administration and
  retention used the Windows administrator. The historical `sqlserver-local`
  pass used that administrator throughout and remains separately retained.
  No PSU internal database was changed.
- **Host and effective settings:** same Windows 11 build 26200, Ryzen 5 9600X,
  31.6 GiB RAM, High performance plan and C: WD_BLACK SN850X NVMe disk 1 as the
  earlier passes. Database/log files were under
  `C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA`; SQL
  data, log and tempdb paths are retained in `server-before.json`. No PostgreSQL
  service was present in this pass. Default dynamic memory settings remained:
  minimum 16 MiB, configured maximum 2,147,483,647 MiB (a ceiling, not allocated
  memory), MAXDOP 12, parallelism cost threshold 5, automatic user connections and
  recovery interval. These budgets were not equalized to the other providers.
  Measured databases used compatibility 170, FULL recovery, CHECKSUM page
  verification, delayed durability disabled, RCSI off, snapshot isolation off and
  accelerated recovery off. FULL recovery alone does not provide a log-backup/PITR
  procedure; no such procedure or crash durability was tested.
- **Equivalent work and material differences:** reused seed-1108 fixtures at
  1,000/256, 10,000/256 and 10,000/2,048. Seven shuffled blocks follow one warm-up
  for eight reads in reuse/new/pooled modes and eight 100-record write cases.
  Uncompressed `nvarchar(max)` stores payloads and JSON text. JSON filters use
  typed, nonpersisted computed columns plus a B-tree index; the separate warmed
  scan phase drops only that index. Estimated XML plans are retained for every
  read and the scan phase; these are not runtime engine timings. SQL Server 2025's
  native JSON type and JSON indexes were not measured. Document projection returns
  typed Id/Name/Cpu columns directly, avoiding a second SQL-generated JSON object.
  Per-row writes prepare typed parameters and commit once/each; `OPENJSON` set
  variants send one prepared JSON recordset. Refresh-set cases send the full
  recordset for key extraction, unlike PostgreSQL's compact key array; they are
  not a tuned update recommendation. Work tables have primary keys without the
  main filter index. JSON preparation remains outside database timers.
- **Boundaries and PSU:** direct outer `Measure-Command` includes helper return,
  SQL, usable object construction and owned connection disposal; serialization
  and assertions follow the clock. Selected authenticated Integrated endpoints
  use pooling and include HTTP response/JSON parsing. Both 1,000-record automation
  imports include fixture decoding/JSON preparation in whole-script clocks;
  jobs include submission, 50 ms completion polling and result retrieval.
  PSU 2026.3.0 and its runtime/environment/security settings are retained;
  harness/PSU runtime versions still differ. Both original preview registrations
  were restored and hash-verified after each pass. SQL authentication used a
  generated demonstration password, loaded into the direct driver's process
  environment before measurement. PSU read a temporary file restricted to the
  current Windows identity and SYSTEM; restoration removed it. Neither password
  nor token is in retained evidence. Unregistered preview code and job history remain.
- **Concurrency and operating checks:** matching warmed, gated independent
  processes ran 200 operations each, one warm-up and three measured bursts for
  one/four readers, one/four writers and three readers plus one writer. Writers
  share ten keys; readers query unchanged records. No retries. Burst wall time
  counts once. All 11,200 operations, result counts, final fields and increments
  passed in each authentication pass. Conflicting-row lock timeout was 250 ms while an independent-row update
  committed. Read committed saw new commits; repeatable read retained shared
  locks and blocked the competing writer. Rollback/reconnect, checksum COPY_ONLY
  backup, VERIFYONLY and an actual restore with full row/document field checks
  passed. `DBCC CHECKDB` passed on the original/restored operational pair and all
  three measured databases. The latter also receive full main-table field checks
  and verified checksum backups during retention.
- **Limits and stopping point:** later unpaired warm local passes, unequal
  memory/storage representations, encryption and provider mappings prevent an
  engine ranking. One-second host counters and process memory are retained;
  `sqlservr` CPU values were unavailable under this diagnostic identity and are
  reported as null, not zero CPU. No paired orchestration control, SQL Server
  endpoint concurrency, cold-cache, sustained-capacity, frontend, remote-host,
  crash, PITR/HA or production-identity tests. Those gaps are not needed to choose
  connection pooling, batching, projection or an operating model for this bounded
  example; further tuning was stopped.
- **Authentication comparison:** at 10,000/256, Windows versus SQL-login medians
  were 2.69 versus 64.8 ms for fresh keyed reads, 0.51 versus 0.43 ms pooled,
  and 17.3 versus 17.5 ms through the pooled PSU endpoint. The SQL-login fresh-key
  observations at all three shapes were approximately 64–66 ms. Microsoft
  documents SQL Server 2025's 100,000-iteration PBKDF2 password verification as
  adding login cost, particularly without pooling. That is a supported explanation,
  not separately measured hashing time. The passes were sequential, with a service
  restart, different identities/privileges and a small authentication-selection
  helper added for the second pass; this is not an isolated authentication-only
  experiment. TLS, driver, fixtures, SQL, durability and timing boundaries remained
  the same. No password-hashing settings were weakened.
- **Artifacts:** portable `database/SqlServerEvidence.json` contains conditions,
  distributions, identity proofs, checks, resource observations and limitations
  for `sqlserver-sql`; `SqlServerWindowsEvidence.json` preserves the Windows baseline.
  Ignored `tools/output/database/sqlserver-sql/` retains JSONL samples, workers, XML
  plans in shape-condition JSON, monitoring, historical source snapshots,
  condition/setup records and SHA256 manifest. `retained/` contains native checksum
  backups of all three measured databases and schema/index/compression metadata;
  `operations/backup.bak` was actually restored. The sibling
  `sqlserver-sql-evidence.zip` and its checksum preserve the pass outside the
  temporary installation. The original `sqlserver-local/` and its evidence ZIP
  retain the Windows baseline and original TCP settings unchanged. Initial
  discovery/setup failures are excluded, before any measurements. The temporary
  installation, mixed authentication, disposable login and loopback TCP remain;
  the owner plans to uninstall SQL Server after this session. Uninstall and Git
  publication are separate work.

Reproduce in PowerShell 7 with the existing bundled driver and a Windows SQL
administrator identity. `-ConfigureTcp` needs an elevated Windows shell, records
the original TCP settings and restarts only the discovered default SQL Server 2025
instance. Omit it if loopback TCP is already configured. Choose a new pass: existing
databases and evidence are never overwritten. Preview setup/restoration requires
the designated dev-psu token. For a new installation, Initialize-SqlServerLogin
creates the SQL login and temporary demonstration password file. Restart
MSSQLSERVER in an elevated shell if its setup record says RestartRequired.
An existing login is never overwritten. Set the process environment before
timers, matching the direct PostgreSQL credential path. The original Windows
mode is still available through `PAR_SQL_AUTHENTICATION=Windows` without a password.
Save validates, backs up and packages the completed pass. On a fresh installation
with TCP disabled, first run `Get-SqlServerCondition -Pass my-sqlserver-setup
-ConfigureTcp` from this script directory in an elevated shell; this bootstrap
record precedes SQL login creation and is not a measured provider pass.

```powershell
$pass = 'my-sqlserver-sql'
# Run Initialize-SqlServerLogin once, then restart if its setup record requires it.
# Choose -Login par_benchmark_<name> if an older login has no available password.
./tools/benchmarks/database/Initialize-SqlServerLogin.ps1
# Restart-Service MSSQLSERVER  # elevated; only if RestartRequired is true
$env:PAR_SQL_AUTHENTICATION = 'Sql'
$env:SQLSERVER_BENCHMARK_LOGIN = (Get-Content C:/dev-psu/sqlserver-benchmark-login.txt -Raw).Trim()
$env:SQLSERVER_BENCHMARK_PASSWORD = (Get-Content C:/dev-psu/sqlserver-benchmark-password.txt -Raw).Trim()
try {
    ./tools/benchmarks/database/Get-SqlServerCondition.ps1 -Pass $pass # add -ConfigureTcp if needed
    ./tools/benchmarks/database/Invoke-SqlServerBenchmark.ps1 -Pass $pass
    ./tools/benchmarks/database/Set-SqlServerPreview.ps1 -Pass $pass
    try {
        ./tools/benchmarks/database/Invoke-SqlServerFollowup.ps1 -EvidencePass $pass
    } finally {
        ./tools/benchmarks/database/Set-SqlServerPreview.ps1 -Pass $pass -Restore
    }
    ./tools/benchmarks/database/Test-SqlServerOperation.ps1 -Pass $pass
    ./tools/benchmarks/database/Invoke-SqlServerConcurrency.ps1 -Pass $pass
    ./tools/benchmarks/database/Save-SqlServerEvidence.ps1 -Pass $pass
} finally {
    Remove-Item Env:/SQLSERVER_BENCHMARK_PASSWORD,Env:/SQLSERVER_BENCHMARK_LOGIN,Env:/PAR_SQL_AUTHENTICATION
    if (Test-Path C:/dev-psu/sqlserver-benchmark-password.txt) {
        Remove-Item -LiteralPath C:/dev-psu/sqlserver-benchmark-password.txt
    }
    if (Test-Path C:/dev-psu/sqlserver-benchmark-login.txt) {
        Remove-Item -LiteralPath C:/dev-psu/sqlserver-benchmark-login.txt
    }
}
```

Provider behavior references: [SQLite WAL](https://www.sqlite.org/wal.html),
[synchronization](https://www.sqlite.org/pragma.html#pragma_synchronous),
[isolation](https://www.sqlite.org/isolation.html),
[backup with VACUUM INTO](https://www.sqlite.org/lang_vacuum.html#vacuum_with_an_into_clause)
and [Microsoft.Data.Sqlite connection settings](https://learn.microsoft.com/en-us/dotnet/standard/data/sqlite/connection-strings).
[Npgsql usage](https://www.npgsql.org/doc/basic-usage.html),
[PostgreSQL 18 JSON types](https://www.postgresql.org/docs/18/datatype-json.html)
and [WAL settings](https://www.postgresql.org/docs/18/runtime-config-wal.html)
explain the PostgreSQL implementation choices.
[SQL Server 2025 editions](https://learn.microsoft.com/en-us/sql/sql-server/editions-and-components-of-sql-server-2025?view=sql-server-ver17)
describes Standard Developer's development/test use;
[TCP configuration](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-a-server-to-listen-on-a-specific-tcp-port?view=sql-server-ver17)
and [JSON computed-column indexes](https://learn.microsoft.com/en-us/sql/relational-databases/json/index-json-data?view=sql-server-ver17)
explain the SQL Server implementation choices.
Microsoft's [SQL Server 2025 login-performance note](https://learn.microsoft.com/en-us/sql/sql-server/sql-server-2025-known-issues?view=sql-server-ver17#pbkdf2-hashing-algorithm-can-affect-login-performance)
explains the password-hashing cost that pooling avoids on repeated requests.
