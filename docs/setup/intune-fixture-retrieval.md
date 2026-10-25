# Intune fixture retrieval

## Synopsis

`ParData` retrieves source objects for scripts, endpoints, and dashboards.
`Get-ParIntuneDevice` reads the versioned Intune CSV and restores SDK models.
The report example consumes those models rather than reading CSV directly.

## Requirements

Use PowerShell 7.1 or later. The Intune command requires an installed
`Microsoft.Graph.DeviceManagement` version 2.41.2 and its Authentication
dependency. These load when retrieval runs; importing ParData alone does not
require Graph. Retrieval does not authenticate or make network requests.

## Configuration

From the repository root:

```powershell
Import-Module ./modules/ParData/ParData.psd1
$devices = @(Get-ParIntuneDevice)
```

In PSU, `.universal/variables.ps1` registers the non-secret `$PAR_FixturePaths`
hashtable with Global scope. Its `IntuneDevice` entry resolves the checked-in
CSV relative to the registration file. The resource's environment must include
`PAR_FixturePaths` or `*` for normal PSU variable injection.

ParData applies configuration per source when imported:

1. Explicit paths supplied through `-ArgumentList` take precedence.
2. The global `$PAR_FixturePaths` hashtable supplies shared values when present.
3. Repository-relative defaults supply omitted sources.

Outside PSU, no registration commands are needed. To use another dataset:

```powershell
$fixturePaths = @{ IntuneDevice = 'C:/demo/intune-devices.csv' }
Import-Module ./modules/ParData/ParData.psd1 -ArgumentList $fixturePaths -Force
$devices = @(Get-ParIntuneDevice)
```

`IntuneDevice` is currently the only supported key. Both configuration layers
reject unknown keys and blank, null, or non-string paths. An existing shared
variable must be a hashtable. Relative configured paths are anchored to the
working directory at import; use absolute paths for portable resource execution.
Reimport with `-Force` to pick up configuration changes. Each retrieval reads
the current file, so replacing its contents does not require reimporting.

## Fixture contract

Generate fixtures with the scripts in `tools/factories/`. Their exporter owns
these 15 case-sensitive column names, each required exactly once; order may vary:

```text
id, userId, deviceName, enrolledDateTime, lastSyncDateTime, operatingSystem,
osVersion, emailAddress, azureADDeviceId, userPrincipalName, model, manufacturer,
serialNumber, userDisplayName, deviceEnrollmentType
```

Retrieval accepts UTF-8 CSV with quoted commas, doubled quotes, multiline cells,
LF or CRLF record separators, and an optional final newline. Nonempty fixtures
need a header; blank records within them are invalid. Additional or missing
columns require an explicit schema change.

- Zero-byte, whitespace-only, and valid header-only files produce no objects.
- `id` and `deviceName` must contain non-whitespace text. Other identifiers remain
  source strings without additional GUID validation.
- Empty user-association cells become null. Other nonempty strings, including
  whitespace, remain unchanged. CSV cannot preserve a distinction between an
  original null and an empty string.
- Empty timestamps become null. Nonempty timestamps must be valid ISO 8601 values
  with `Z` or a numeric offset and at most seven fractional digits. Retrieval
  normalizes them to UTC before SDK deserialization.
- Empty enrollment type is omitted from deserialization. Nonempty text is passed
  to the SDK unchanged, including values accepted by its extensible enum.

Command help describes the returned model and failure behavior:

```powershell
Get-Help Get-ParIntuneDevice -Full
```

## Verification

```powershell
Invoke-Pester -Path ./modules/ParData, ./tools/factories -Output Detailed
```

These tests exercise the installed SDK, checked-in data, temporary fixtures,
configuration precedence, CSV restoration, and factory/exporter integration.
Project-wide verification gaps are recorded in errata, available from the index.
