# psu-agent-reference

A living PowerShell Universal reference for AI agents and the people directing them.

This project will demonstrate realistic, idiomatic PowerShell and PSU implementations for Windows and Microsoft platform administrators. The implementation is the educational resource.

The repository is being established; PSU demonstrations will follow.

- [Project brief](PROJECT-BRIEF.md): purpose, boundaries, and implementation constraints.
- [Contributing](CONTRIBUTING.md): agent workflow, Git commands, and attribution.
- [SSH key API tool](docs/setup/ssh-key-api.md): manage PSU SSH keys with named PowerShell parameters.
- [Git settings API tool](docs/setup/git-settings-api.md): manage saved Git configurations with named parameters and a settings hashtable.
- [Synthetic device factories](tools/factories/README.md): create offline Intune SDK models and CSV fixtures.
- [Intune fixture retrieval](docs/setup/intune-fixture-retrieval.md): configure offline retrieval of managed-device SDK models for dashboard and reporting consumers.
- [Issues](https://github.com/ingenite/psu-agent-reference/issues) and [Project board](https://github.com/users/ingenite/projects/2): planned and active work.

## Directory structure

| Directory | Purpose |
| --- | --- |
| `.universal/` | PSU resource registrations and configuration. |
| `endpoints/` | API endpoint implementation scripts. |
| `scripts/` | PSU automation scripts. |
| `dashboards/` | Universal Dashboard (UD) app implementations and their dashboard-specific companion modules. |
| `modules/` | PowerShell modules shared across PSU scripts, endpoints, and dashboards; custom commands use the `PAR` noun prefix. |
| `data/` | Versioned synthetic datasets for demonstrations. |
| `tools/` | Utilities run explicitly for development or host administration. |
| `tools/factories/` | Synthetic-data factory and export scripts, with offline model probes. |
| `docs/adr/` | Architecture decision records; see [ADR-0000](docs/adr/0000-record-architecture-decisions.md). |
| `docs/setup/` | Bootstrap, deployment, and recovery instructions. |

Empty directories contain `.gitkeep` placeholders so Git preserves the scaffold.
Pester tests live beside the scripts or modules they test, using the filename
`<Name>.Tests.ps1`.

Keep helpers used only within one dashboard in its companion module, for example
`MyDashboard.psm1` beside `MyDashboard.ps1`. PSU automatically includes an
[app's companion module](https://docs.devolutions.net/powershell-universal/apps/building-dashboards#module).
Code shared across multiple PSU resources belongs in top-level `modules/`.
`ParData` owns shared source-data retrieval; each command defines its own source
model contract and dependencies, allowing Graph and other model types to coexist.

Shared PSU variables are defined in `.universal/variables.ps1` and use the
`PAR_` prefix, for example `$PAR_FixturePaths`. Reusable modules provide local
development defaults when the corresponding PSU variable is absent.

Licensed under the [Mozilla Public License 2.0](LICENSE).
