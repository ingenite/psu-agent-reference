# Documentation index

This reference is intended for agents and the administrators directing them.
Start with a task below, read the relevant source and command help, and consult
the errata before drawing conclusions about deployment or live service behavior.
The same documentation serves both audiences; there is no separate agent manual.

## Explore and use the examples

The synthetic workflow uses related Intune devices, Entra users, and CMDB assets.
Factories generate source objects, `ParData` retrieves them from fixtures, and
`ParReports` applies report and resolution rules. The guides below cover these
stages of the same workflow.

| Task | Reference |
| --- | --- |
| Ask an agent to explain or adapt an example | [Example prompts](prompts.md) |
| Understand known limitations and verification gaps | [Errata](errata.md) |
| Prepare synthetic device, user, and asset data | [Generation](setup/fixture-generation.md), [retrieval](setup/fixture-retrieval.md), SDK probes: [Intune](../tools/factories/Test-IntuneDeviceModel.ps1) and [Entra](../tools/factories/Test-EntraUserModel.ps1) |
| Understand the device-assignment investigation experience | [Investigation workflow and acceptance scenarios](reports/device-assignment-investigation.md) |
| Use the implemented report and supporting transformations | [Missing-primary-user report](reports/intune-devices-without-primary-user.md), [device correlation](reports/intune-cmdb-correlation.md), [assigned-user resolution](reports/cmdb-assigned-user-resolution.md), [assignment comparison](reports/device-assignment-comparison.md) |
| Understand the introductory PSU automation | [Show-HelloWorld](../scripts/Show-HelloWorld.md) |
| Manage PSU Git configuration and access | [Git settings API](setup/git-settings-api.md), [SSH key API](setup/ssh-key-api.md) |
| Generate a JWT signing key locally | [Signing-key tool and help](../tools/New-JwtSigningKey.ps1) |
| Inspect the optional contributor-local vault setup | [SecretStore tool and help](../tools/Initialize-SecretVault.ps1) |

Run command examples from the repository root unless stated otherwise. Command
help owns parameter details, output, and command-specific behavior. For example:

```powershell
Get-Help ./tools/Invoke-GitSettingsApi.ps1 -Full
Import-Module ./modules/ParReports/ParReports.psd1
Get-Help Get-ParIntuneDeviceWithoutPrimaryUserReport -Full
```

For PSU Management API request and response schemas, use your instance's
`/swagger/index.html`.

## Work in the repository

`AGENTS.md` contains instructions for developing this reference. A separate
`AGENTS.production.md` is planned for downstream adoption of the whole repository;
when it ships, adopters will rename it to `AGENTS.md` in their own copy. It is not
available yet.

| Task | Reference |
| --- | --- |
| Choose file locations | [Directory guide](directory-guide.md) |
| Read agent instructions | [AGENTS.md](../AGENTS.md) |
| Review and deliver a change | [Contributing](../CONTRIBUTING.md) |

## Architecture decisions

ADRs record lasting choices and their reasons. Read the decisions relevant to
the task; proposed records do not establish project requirements.

| Record | Decision |
| --- | --- |
| [0000](adr/0000-record-architecture-decisions.md) | Record architecture decisions |
| [0001](adr/0001-prefer-powershell-7.md) | Prefer PowerShell 7 |
| [0002](adr/0002-standardize-powershell-names.md) | Standardize PowerShell names |
| [0003](adr/0003-define-par-identity.md) | Define PAR identity |
| [0004](adr/0004-prefer-idiomatic-powershell.md) | Prefer idiomatic PowerShell |
| [0005](adr/0005-develop-in-source-deploy-through-git.md) | Develop in source; deploy through Git |
| [0006](adr/0006-standardize-shared-psu-configuration.md) | Standardize shared PSU configuration |
| [0007](adr/0007-place-modules-by-responsibility.md) | Place modules by responsibility |
| [0008](adr/0008-define-documentation-ownership.md) | Define documentation ownership |
| [0009](adr/0009-use-fixed-agent-attribution.md) | Use fixed agent attribution |
