# Errata

Open verification gaps only: one row per gap, deleted when it closes (ADR-0010).
Tests use synthetic data and mocked services, so none of them proves live PSU,
Graph, CMDB or tenant behavior. Live development-instance checks are recorded in
PR descriptions (`git log`).

| Area | Unverified or limited | Evidence |
| --- | --- | --- |
| Live services | Graph, CMDB, tenant data and permissions have never been exercised. | `modules/ParData` reads fixtures only |
| Synchronized PSU | Live checks used a PSU 2026.3.0 development instance, not one synchronized from Git. | ADR-0005 |
| Page discovery | A new `-AutoInclude` page needed a forced Reload, not just an app restart; automatic discovery timing is unknown. | `tools/Invoke-DevPsuDashboardReload.ps1` |
| Shared variables | Object-valued variable injection was unreliable, so `PAR_FixturePaths` is a JSON string. | `.universal/variables.ps1` |
| Primary user | The report treats a missing `UserId` as no primary user; Graph's primary-user relationship is not queried. | `Get-Help ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport` |
| Enrollment types | No verified mapping from Autopilot deployment modes to the synthetic enrollment types. | `Get-Help ./tools/factories/New-FakeIntuneDevice.ps1` |
| CMDB identity | CMDB schema and person-to-UPN mappings are demonstration choices; a unique match does not verify identity or source freshness. | `data/cmdb-person-mappings.csv` |
| Serial numbers | A serial can appear on several Intune records; a match identifies a candidate CMDB asset, not a unique device. | `Get-Help Resolve-ParIntuneDeviceCmdbAsset` |
| Management API writes | Git-settings and SSH-key save, create, rename and delete were tested only against mocks; live reads worked. | `tools/Invoke-GitSettingsApi.Tests.ps1`, `tools/Invoke-SshKeyApi.Tests.ps1` |
| SSH key reference | How `gitSshKey` maps to an SSH-key response, and unattended Git access under the PSU service account, are unverified. | `Get-Help ./tools/Invoke-GitSettingsApi.ps1 -Parameter GitSshKey` |
| Git hosts | Only GitHub has been used. Saving Git settings does not prove the configuration is active or can reach its remote. | ADR-0005 |
| PSU benchmarks | Cache restart survival, the stored `Persistent` flag and the cause of concurrent endpoint slowdown are unresolved. | `tools/benchmarks/Findings.md` |
| Database benchmarks | One workstation, unpaired passes; small-shape read medians can vary about 2× between passes; no remote, crash, HA or production-identity tests. | `tools/benchmarks/DatabaseProviders.md` |
