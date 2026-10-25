# Directory guide

Choose locations by responsibility. ADR-0007 governs module placement; command
and module names follow ADR-0002 and ADR-0003.

| Location | Purpose |
| --- | --- |
| `.universal/` | PSU resource registrations and configuration, including shared variables. |
| `endpoints/` | API endpoint implementation scripts. |
| `scripts/` | PSU automation scripts and adjacent resource documentation. |
| `dashboards/` | Dashboard implementations and their dashboard-specific companion modules. |
| `modules/` | PowerShell modules shared by scripts, endpoints, and dashboards. |
| `data/` | Versioned synthetic datasets. |
| `tools/` | Utilities run explicitly for development or host administration. |
| `tools/factories/` | Synthetic-data factories, exporters, and offline model probes. |
| `tools/output/` | Generated probe results; ignored by Git. |
| `docs/` | Documentation index, example prompts, directory guide, and errata. |
| `docs/adr/` | Architecture decision records. |
| `docs/setup/` | Configuration and setup procedures. |
| `docs/reports/` | Report scenarios and interpretation. |

Pester tests live beside the code they test as `<Name>.Tests.ps1`. Empty scaffold
directories may contain `.gitkeep` placeholders.

`ParData` retrieves source objects. `ParReports` queries and transforms those
objects. Resource scripts and dashboards compose those commands for their own
presentation or orchestration needs. Add abstractions when an actual shared
responsibility emerges; do not build a speculative framework.
