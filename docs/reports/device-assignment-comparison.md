# Device assignment comparison

Use `Compare-ParDeviceAssignedUser` from `ParReports` to compare each Intune
device's `UserId` with the Entra ID resolved from its CMDB assigned-person
reference. The command composes the existing serial-number correlation and
explicit person-reference-to-UPN resolution rules over supplied source objects.
Results distinguish `Match`, `Mismatch`, `MissingAssignment`, and `Unresolved`,
with reasons and the nested resolver evidence retained for review.

A comparison requires one CMDB asset and a known assignment state. A blank CMDB
person reference means no recorded assignment; a nonblank reference with missing
or ambiguous identity evidence remains unresolved. Missing or ambiguous asset
correlation also remains unresolved, including when Intune has no user ID.
Two missing assignments are reported as missing, rather than a match. These
outcomes describe the supplied records; they do not establish a need for action.

For the complete decision order, output fields, and default-fixture example:

```powershell
Import-Module ./modules/ParReports/ParReports.psd1
Get-Help Compare-ParDeviceAssignedUser -Full
```

## Deterministic comparison scenarios

The separate `data/assignment-comparison/` dataset exercises all comparison
outcomes without changing the original retrieval and resolver examples. Files
use the existing source CSV contracts. All IDs, dates, serials, and mappings are
fixed demonstration values; duplicate records are intentional.

Run from the repository root:

```powershell
$fixturePaths = @{
    IntuneDevice = './data/assignment-comparison/intune-devices.csv'
    CmdbAsset = './data/assignment-comparison/cmdb-assets.csv'
    EntraUser = './data/assignment-comparison/entra-users.csv'
}
Import-Module ./modules/ParData/ParData.psd1 -ArgumentList $fixturePaths -Force
Import-Module ./modules/ParReports/ParReports.psd1
$devices = @(Get-ParIntuneDevice)
$parameters = @{
    CmdbAsset = @(Get-ParCmdbAsset)
    PersonMapping = @(Import-Csv -LiteralPath ./data/assignment-comparison/cmdb-person-mappings.csv)
    EntraUser = @(Get-ParEntraUser)
}
$results = @($devices | Compare-ParDeviceAssignedUser @parameters)
$results | Select-Object IntuneDeviceId, Outcome, Reason
```

The serial suffix identifies each scenario:

| Serial | Scenario | Outcome / reason |
| --- | --- | --- |
| `COMPARE-001` | Both assignments resolve to Alex | `Match / SameUserId` |
| `COMPARE-002` | Intune identifies Blair; CMDB resolves to Alex | `Mismatch / DifferentUserIds` |
| `COMPARE-003` | Intune has no user ID; CMDB resolves to Alex | `MissingAssignment / IntuneAssignmentMissing` |
| `COMPARE-004` | Intune identifies Alex; CMDB reference is blank | `MissingAssignment / CmdbAssignmentMissing` |
| `COMPARE-005` | Both assignments are blank | `MissingAssignment / BothAssignmentsMissing` |
| `COMPARE-006` | No CMDB asset; Intune also has no user ID | `Unresolved / CmdbAssetMissing` |
| `COMPARE-007` | Two CMDB assets, both referring to Alex | `Unresolved / CmdbAssetAmbiguous` |
| `COMPARE-008` | Nonblank CMDB reference has no mapping; Intune has no user ID | `Unresolved / CmdbAssignedUserUnresolved` |
| `COMPARE-009` | Two identical person mapping rows | `Unresolved / CmdbAssignedUserUnresolved` |
| `COMPARE-010` | Mapped UPN has no Entra candidate | `Unresolved / CmdbAssignedUserUnresolved` |
| `COMPARE-011` | Mapped UPN has two Entra candidates | `Unresolved / CmdbAssignedUserUnresolved` |

Inspect `Correlation.Reason` or `AssignedUserResolution.Reason` for the specific
unresolved cause. The sibling `ParReports.Tests.ps1` checks these fixtures through
`ParData`, including restored Intune and Entra SDK models, and separately tests
blank values, literal ID comparison, input order, and source preservation.

The import configuration persists for that `ParData` module instance. Remove it
and import again without `-ArgumentList` to return to the normal configuration:

```powershell
Remove-Module ParData
Import-Module ./modules/ParData/ParData.psd1
```
