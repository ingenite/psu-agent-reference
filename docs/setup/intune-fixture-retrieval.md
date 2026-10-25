# Intune fixture retrieval

`ParData` provides shared source-data retrieval for PSU scripts, endpoints, and
dashboards under [issue #20](https://github.com/ingenite/psu-agent-reference/issues/20).
It requires PowerShell 7.1 or later. Each source command owns its model contract
and dependencies; the module can accommodate sources using Graph SDK models or
other types. Its first command, `Get-ParIntuneDevice`, retrieves offline Intune
fixtures and requires an installed `Microsoft.Graph.DeviceManagement` version
2.41.2. That exact SDK version and its Authentication dependency load when the
Intune command runs. Importing `ParData` alone does not load or require Graph.
Retrieval does not authenticate or make Graph requests.

Shared retrieval belongs in top-level `modules/`. Helpers used only within one
dashboard belong in that dashboard's companion module, as described in the
[directory guide](../../README.md#directory-structure).

## Configure and retrieve

From the repository root:

```powershell
Import-Module ./modules/ParData/ParData.psd1
$devices = @(Get-ParIntuneDevice)
```

In PSU, [variables.ps1](../../.universal/variables.ps1) registers the non-secret
`$PAR_FixturePaths` hashtable with Global scope. Its `IntuneDevice` entry points
to `data/intune-devices.csv` relative to that configuration file, so it follows
the repository's deployment location. Shared PSU variable names use the
`PAR_` prefix. Resources use normal PSU variable injection; their environment
must include `PAR_FixturePaths` (or `*`). See
[PSU Variables](https://docs.devolutions.net/powershell-universal/platform/variables).

When importing `ParData`, configuration is applied per source in this order:

1. Explicit fixture paths passed through `-ArgumentList`.
2. The global `$PAR_FixturePaths` hashtable, when present.
3. Repository-relative defaults built into the module.

Outside PSU, no PSU cmdlets or registration scripts are needed. With no shared
variable or explicit override, the default source is the versioned
`data/intune-devices.csv`, resolved relative to the module. To override a fixture
explicitly, pass its path when importing:

```powershell
$fixturePaths = @{ IntuneDevice = 'C:/demo/intune-devices.csv' }
Import-Module ./modules/ParData/ParData.psd1 -ArgumentList $fixturePaths -Force
$devices = @(Get-ParIntuneDevice)
```

The shared variable and explicit argument are hashtables keyed by source;
`IntuneDevice` is currently the only supported key. Omitted sources retain the
lower-precedence setting. An existing shared variable must contain a hashtable;
null or other values fail import. Both configuration layers reject unknown keys
and blank, null, or non-string paths rather than silently falling back.
Relative configured paths are anchored to the working directory at import. Use
`-Force` when reimporting to pick up configuration changes, including changes to
the shared variable. No file is created or
modified by retrieval; a missing or unreadable fixture fails when retrieval runs.
Each call reads the current fixture, so replacing the data does not require
reimporting the module. The configured path is interpreted literally.

## Retrieval contract

Dashboard and reporting code call `Get-ParIntuneDevice` without storage parameters.
It emits zero or more actual Graph SDK managed-device objects implementing
`Microsoft.Graph.PowerShell.Models.IMicrosoftGraphManagedDevice`. Wrap calls in
`@(...)` when a collection is needed, including for zero or one result. Consumer
code should depend on that interface and its source properties rather than CSV
rows or a report-specific shape.

The implementation lives in `modules/ParData/Public/Get-ParIntuneDevice.ps1`.
Additional source commands can define their own return types, fixture schemas,
and dependencies alongside it without changing the Intune model contract.

The command returns all fixture records in their stored order. It does not filter
by operating system or user assignment, deduplicate, generate data, interpret
assignment status, or produce report rows. No live provider is implemented.

## Fixture format and failures

Use the [factory and exporter](../../tools/factories/README.md) to regenerate
fixtures. Retrieval accepts their 15-column CSV schema. Column names are case
sensitive and must each appear exactly once; column order may vary. Additional or
missing columns require an explicit schema change. UTF-8 CSV supports quoted
commas, doubled quotes, multiline cells, LF or CRLF record separators, and an
optional final newline. Nonempty fixtures require a header; blank records within
them are invalid.

- Zero-byte, whitespace-only, and valid header-only files return no objects.
- Missing or unreadable files raise a terminating error identifying the path.
- Broken CSV quoting, wrong record widths, and incompatible headers raise
  terminating errors. These checks prevent native CSV conversion from silently
  discarding surplus cells or accepting incomplete records.
- `id` and `deviceName` must contain non-whitespace text. Other identifiers remain
  source strings; retrieval does not impose additional GUID or identity rules.
- Empty `userId`, `emailAddress`, `userPrincipalName`, and `userDisplayName` cells
  become actual null values. Nonempty strings, including whitespace, are preserved
  for later reporting policy. CSV cannot distinguish an original null from an
  original empty string.
- Empty timestamps become null. Nonempty timestamps must be valid ISO 8601 values
  with an explicit `Z` or numeric offset; fractional seconds of up to seven digits
  are supported. They are normalized to UTC before SDK deserialization and returned
  as the SDK's date values. Local-time-only and invalid calendar values fail.
- An empty enrollment type is omitted from deserialization. Nonempty enrollment
  text is passed to the SDK unchanged, including values its extensible enum accepts.
  Retrieval does not infer an enrollment mode from device or user details.

All records are restored before any devices are emitted. A bad later record
therefore fails the whole call, with path and data-record context, rather than
returning a partial dataset. Record numbers count data records, starting at one;
quoted multiline values do not change that count.

The source fields follow Microsoft's
[managedDevice resource](https://learn.microsoft.com/en-us/graph/api/resources/intune-devices-manageddevice?view=graph-rest-1.0).
The CSV structure checks account for the permissive behavior documented for
[Import-Csv](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/import-csv).

## Offline verification

```powershell
Invoke-Pester -Path ./modules/ParData, ./tools/factories -Output Detailed
git diff --check
```

Tests exercise the real installed SDK, the checked-in dataset, and temporary
fixtures, including factory/exporter integration. They cover model values, null
normalization, timestamp restoration, configuration precedence, PowerShell
hashtable serialization, empty datasets, and invalid fixtures. Shared-variable
tests set a global variable in the test process. No authentication or Graph
requests are made.
These checks do not verify live PSU variable injection or Graph retrieval.
The [Windows devices without a primary user report](../reports/intune-devices-without-primary-user.md)
consumes this retrieval contract. Dashboard UI and HTTP endpoints remain subsequent work.
