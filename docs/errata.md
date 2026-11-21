# Errata and verification limits

This is the authoritative record of known limitations and verification gaps.
Update the relevant entry when evidence changes.

Unless a live check is explicitly identified, verification uses synthetic data,
isolated tests, and offline probes. These checks do not establish live PSU or
external-service behavior, permissions, or compatibility beyond the documented
dependency versions. Using actual SDK models or vendor documentation does not
extend that verification scope.

## Interpretation limits

The primary-user report uses a missing `UserId` as its demonstration selection
rule. Primary User is the intended terminology for the single-user Windows
scenario; this limitation does not require a different report label. The current
implementation does not separately query Graph's primary-user relationship.
No verified mapping from Autopilot deployment modes to the synthetic enrollment
types is provided.

The CMDB schema and person-to-UPN mappings are demonstration choices, not a vendor
API contract or verified identity directory. CMDB person references are distinct
from Entra IDs. Unique matches in supplied datasets do not independently verify
identity or the accuracy, freshness, and completeness of live sources.

Serial numbers can occur on multiple Intune device records, although uncommon; a serial-number match identifies a candidate CMDB asset, not a unique Intune record.

## PSU execution

PSU 2026.3.0 development-instance checks exercised synthetic module loading,
JSON fixture-path injection, both reports, shared investigation modals, candidate
evidence, refresh, loading, empty results, failure/retry, and light/dark layouts.
Pages declare `-AutoInclude`; reloading `dashboards.ps1` through the management
API activated the updated declarations. The simplified bootstrap and default
theme were checked through the Reports home page, both report routes,
Reports-only navigation, and light/dark report and investigation-modal rendering.
In the owner's new-page test, an app restart did not make the copied page
available; forcing the pending file-change Reload did. Automatic discovery timing
remains unverified. Module changes were checked after an app restart.
Page-owned report composition and argument-free refresh were rechecked in both
reports, including stale-selection rejection, retained search/filter controls on
modal close, candidate evidence, and empty/failure/retry states.
The PITI command refactor was checked after a development-app restart: the
companion imported and re-exported the adjacent implementation module, both
reports rendered table summaries and refreshed their dynamic content, and
investigation callbacks rendered assignments and expandable Intune/CMDB evidence.
Object-valued variable injection was unreliable here, so fixture paths use JSON.
The synchronized instance and live Graph, CMDB, tenant data, and permissions
remain unverified.

## Database provider experiment

Independent review found that the initial workers warmed reads even when assigned
to write, and PostgreSQL/SQL Server measured indexed reads before a separate scan
phase. Current scripts use ten checked operations of each worker's assigned role,
verify/reset warm-up increments before the gate, and counterbalance paired index
conditions with ten checked warm-ups outside each clock. SQL Server was first
rerun with this protocol (`sqlserver-reviewed`); the portable SQLite/PostgreSQL
files retain their historical evidence. The new SQL Server pass passed full direct/PSU/concurrency
and operational checks, using a new non-sysadmin disposable SQL login provisioned
through Windows authentication. Its paired index advantage held in six of seven
10,000/2,048 observations but in none of the seven 10,000/256 observations.
Residual first-operation latency and substantial changes in untouched write
paths limit steady-state and causal before/after interpretations. The old SQL
portable evidence remains unchanged; SqlServerReviewedEvidence.json and the
database review comparison document record the new results. Temporary PSU
registrations were restored and both credential/login-selector files removed.

November 20 repeated passes ran each provider's complete corrected workflow three
times; all passed validation, but single passes disagreed. SQLite's and SQL
Server's first passes and PostgreSQL's second key-order pass differed from the
other two by up to about a factor of two in sequential direct reads, mostly at
1,000 records. The cause was not isolated, so single-pass small-shape read
medians remain uncertain. Unordered PostgreSQL writer increments deadlocked 45 times
in one four-writer burst; the increment now locks rows in key order, which lowers
writer throughput, so PostgreSQL writer bursts compare only with key-order passes.
These passes did not change the portable evidence files, add a paired orchestration
control or test the SQL Server update (17.0.1155.3) against its earlier build.

The SQLite, native Windows PostgreSQL 18.6 and SQL Server 2025 Standard Developer
(17.0.1000.7) experiments exercised seeded local
application databases, direct PowerShell access, authenticated Integrated endpoints,
automation imports, short direct read/write bursts, isolation/locking, rollback,
backup and reopen on the dedicated PSU 2026.3.0 instance. PostgreSQL also passed
logical dump/restore field checks and native relation checks; SQLite exercised
WAL checkpoint behavior. SQL Server passed checksum backup/actual restore,
full main-table field checks and DBCC CHECKDB on all three measured databases
and the operational/restored pair. Its default read committed used locks (RCSI
off); repeatable read blocked a competing writer. PostgreSQL and SQL Server
endpoint concurrency was not repeated. None tested remote hosts/storage, frontend behavior,
sustained capacity, cold-cache behavior, crash/power-loss durability, PITR/HA or
production service-account permissions. Provider passes were separate, used
different connection/pooling and cache budgets, and do not isolate engine speed.
Repeated ASCII payloads compress unusually well under PostgreSQL TOAST, limiting
size and payload-performance conclusions. The direct harness and PSU used different
PowerShell/.NET runtime versions. Brief one-second resource samples do not explain
individual slow requests; PostgreSQL and SQL Server passes had no paired orchestration
control. SQL Server process CPU values were unavailable under the diagnostic
identity; host counters and process memory were retained. SQL Server used encrypted
TCP with an unvalidated local certificate, default dynamic memory settings and
uncompressed Unicode JSON text/computed indexes. Its original Windows-authenticated
pass used administrative access; a separately retained full follow-up used local
SQL login par_benchmark_sql, no server administrative role and ownership of only
the dedicated benchmark databases. Direct, endpoint and job identity probes passed;
backup/provisioning administration still used Windows access. SQL authentication
raised fresh keyed-read latency to about 65 ms while pooled reads stayed below
1 ms; provider passes do not separately isolate password hashing, TLS or privileges.
Native SQL Server 2025 JSON types/indexes,
snapshot isolation and least-privilege production identities were not tested.
The databases are separate from PSU's internal database; the harness remains
experimental. Both server providers' evidence and backups are retained outside
their temporary installations. Temporary PSU registrations were restored; the SQL
login's temporary password file was removed and no password is in evidence.
The SQL Server installation was uninstalled after the November 20 passes. The
reinstalled PostgreSQL listened on all interfaces; benchmark connections used loopback.

## Management API tools and Git

The Git settings and SSH-key wrappers were checked against PSU 2026.3.0's
Management API schema. Unlike the offline checks above, live read access was
checked separately during development. Their sibling tests mock HTTP calls;
live save, create, rename, and delete behavior remains unverified.

The mapping from the Git settings API's `gitSshKey` string to an SSH-key response
has not been verified. SSH key selection and unattended Git access under the PSU
service account remain deployment-specific verification work. The guides target
GitHub; other Git hosts have not been verified.

Saving settings does not prove that a configuration is assigned, active, or able
to reach a Git remote. Confirm effective configuration and a fresh relevant
operation when verifying a deployment.
