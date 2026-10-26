# Fixture retrieval

`ParData` retrieves offline source objects for scripts, endpoints, and dashboards.
It restores SDK models for Intune devices and Entra users, and plain PowerShell
objects for CMDB assets.

| Configuration key | Command | Default fixture |
| --- | --- | --- |
| `IntuneDevice` | `Get-ParIntuneDevice` | `data/intune-devices.csv` |
| `EntraUser` | `Get-ParEntraUser` | `data/entra-users.csv` |
| `CmdbAsset` | `Get-ParCmdbAsset` | `data/cmdb-assets.csv` |

## Configuration

At import, ParData selects a path independently for each source, in this order:

1. Explicit paths supplied through `Import-Module -ArgumentList`.
2. Global `$PAR_FixturePaths`, registered in `.universal/variables.ps1` for PSU.
3. The repository-relative defaults above for omitted sources.

Both configuration layers accept hashtables using the keys above and reject
unknown keys and blank, null, or non-string paths. The PSU execution environment
must include `PAR_FixturePaths` or `*` for variable injection; outside PSU, no
registration commands are needed.

Relative configured paths are anchored to the working directory at import.
Use absolute paths for portable resource execution. Reimport with `-Force` to
apply configuration changes. Each retrieval reads the current file, so replacing
its contents does not require reimporting.

For example, from the repository root, override two sources and retain the
configured or default Intune path:

```powershell
$fixturePaths = @{
    EntraUser = 'C:/demo/entra-users.csv'
    CmdbAsset = 'C:/demo/cmdb-assets.csv'
}
Import-Module ./modules/ParData/ParData.psd1 -ArgumentList $fixturePaths -Force
$devices = @(Get-ParIntuneDevice)
$users = @(Get-ParEntraUser)
$assets = @(Get-ParCmdbAsset)
```

Importing ParData loads no Graph modules. Each SDK dependency loads only when its
retrieval command runs; CMDB retrieval requires none.

## Fixtures

The fixture generation guide provides repeatable examples using the source
factories and exporters in `tools/factories/`. Retrieval validates
the entire dataset before returning records and preserves IDs, order, and
duplicates. CSV cannot distinguish an original null from an empty string.
