# CMDB assigned-user resolution

Use `Resolve-ParCmdbAssignedUser` from `ParReports` to resolve each CMDB asset's
assigned-person reference through an explicit person-reference-to-UPN mapping
and a supplied Entra user dataset. UPN is the chosen account attribute because
it ordinarily identifies one account; duplicates in either stage remain
ambiguous. Results retain the source records and mapping evidence.

The synthetic `data/cmdb-person-mappings.csv` connects the opaque CMDB person
references to the existing Entra fixture. Supply these mapping rows explicitly;
they are demonstration assertions rather than a discovered CMDB relationship.
This command does not compare Intune assignments or choose a CMDB device candidate.

For comparison rules, missing and ambiguous outcomes, output fields, and
deterministic examples:

```powershell
Import-Module ./modules/ParReports/ParReports.psd1
Get-Help Resolve-ParCmdbAssignedUser -Full
```
