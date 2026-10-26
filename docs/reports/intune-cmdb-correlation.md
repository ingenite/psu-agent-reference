# Intune device and CMDB asset correlation

Use `Resolve-ParIntuneDeviceCmdbAsset` from `ParReports` to evaluate each Intune
record against a supplied CMDB dataset by serial number. Results distinguish
unique, missing, and ambiguous candidates while preserving each Intune record
and the candidate CMDB evidence. Retrieve source objects through `ParData` or
supply objects already in memory.

For comparison rules, output fields, and usage examples:

```powershell
Import-Module ./modules/ParReports/ParReports.psd1
Get-Help Resolve-ParIntuneDeviceCmdbAsset -Full
```
