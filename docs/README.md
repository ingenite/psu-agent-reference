# Documentation index

Repository docs are for agents: short notes that give the reason for a choice and
point to the evidence. Human guides are in the
[GitHub Wiki](https://github.com/ingenite/psu-agent-reference/wiki). ADR-0010
explains the split. Read `errata.md` before claiming anything about live behavior.

## Find the evidence

| Need | Look at |
| --- | --- |
| What is unverified | `docs/errata.md` |
| Where files belong | `docs/directory-guide.md`, ADR-0007 |
| Command parameters, outputs and side effects | `Get-Help <command> -Full` after importing the module, or `Get-Help ./path/script.ps1 -Full` |
| Source retrieval and fixture configuration | `modules/ParData` help; `.universal/variables.ps1` |
| Report, correlation and comparison rules | `modules/ParReports` help |
| Shared demonstration scenarios | `data/`, exercised by `modules/ParReports/ParReports.Tests.ps1` |
| Synthetic data creation | `tools/factories/` help; SDK model probes `Test-IntuneDeviceModel.ps1`, `Test-EntraUserModel.ps1` |
| Device-assignment app constraints | `dashboards/ParITInternal/README.md` |
| Page layout templates | `dashboards/SimpleTemplates/`, `dashboards/MaterialTemplates/` |
| Design-principles example | `modules/ParVolumeReport/`, `scripts/Get-VolumeSpaceReport.md` |
| PSU Git settings and SSH keys | `tools/Invoke-GitSettingsApi.ps1`, `tools/Invoke-SshKeyApi.ps1` help |
| Management API schemas | Your instance's `/swagger/index.html` |
| Experimental performance results | `tools/benchmarks/Findings.md`, `tools/benchmarks/DatabaseProviders.md` |
| Tests, analysis and delivery | `CONTRIBUTING.md` |

Run commands from the repository root. Wiki drafts are reviewed in `wiki/` before
publication (ADR-0010).

## Architecture decisions

ADRs record lasting choices and the reasons for them. Proposed records are not
requirements.

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
| [0008](adr/0008-define-documentation-ownership.md) | Define documentation ownership (superseded) |
| [0009](adr/0009-use-fixed-agent-attribution.md) | Use fixed agent attribution |
| [0010](adr/0010-separate-agent-and-human-documentation.md) | Separate agent and human documentation |
