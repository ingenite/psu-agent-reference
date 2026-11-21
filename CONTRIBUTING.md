# Contributing

Only invited collaborators can contribute code; public pull requests are not
accepted. Public participation will focus on feature requests and bug reports,
through a channel still to be decided.

Agents: follow [AGENTS.md](AGENTS.md). Changes to the running PSU instance need
separate authorization, and its managed Repository is read-only.

## Workflow

1. Agree a bounded issue with acceptance criteria, add it to the GitHub Project,
   and set it to **In Progress**.
2. Branch from current `main`, make the scoped change and run the checks below.
3. Open a PR with `Closes #<issue>`. Describe the result, what you verified (live
   or offline), and what remains unverified.
4. Squash merge when authorized, set the Project item to **Done**, and delete the
   branch.

`main` is protected: PRs only, no force pushes, and the **Pester (full suite)**
and **PSScriptAnalyzer** checks must pass. Reviewer approvals start at zero to
allow a solo workflow.

The agent skills [start-work](.agents/skills/start-work/SKILL.md),
[submit-work](.agents/skills/submit-work/SKILL.md) and
[finish-work](.agents/skills/finish-work/SKILL.md) carry out these steps, including
the Git commands. A status question such as "are we synced?" never authorizes
edits, publication or cleanup. ADR-0009 defines commit and PR attribution.

## Tests and analysis

Use PowerShell 7.4 or later on Windows. Build tasks never install dependencies,
so CI and local runs use exactly the pinned versions. Install them once:

```powershell
$dependencies = Import-PowerShellDataFile ./tools/BuildDependencies.psd1
foreach ($dependency in $dependencies.GetEnumerator()) {
    Install-PSResource -Name $dependency.Key -Version $dependency.Value -Repository PSGallery -Scope CurrentUser -TrustRepository
}
```

Then, from the repository root in a fresh session:

```powershell
$dependencies = Import-PowerShellDataFile ./tools/BuildDependencies.psd1
Import-Module InvokeBuild -RequiredVersion $dependencies.InvokeBuild
Invoke-Build                       # Full Pester suite
Invoke-Build Test -Suite Dashboards,Data,Reports
Invoke-Build Analyze               # PSScriptAnalyzer
Invoke-Build Analyze,Test          # Both; required before a PR
```

| Suite | Test locations |
| --- | --- |
| `All` (default, used alone) | Every `*.Tests.ps1` outside `tools/output/` |
| `Data` | `modules/ParData/` |
| `Reports` | `modules/ParReports/` |
| `Dashboards` | `dashboards/` (offline composition and state) |
| `Factories` | `tools/factories/` |
| `Tools` | Tests directly in `tools/` |

Suites are chosen by location, not dependency analysis. Pick the changed area plus
its consumers: a factory change, for example, also affects `Data` and the reports
that use it. Results go to `tools/output/tests/` (NUnit XML) and
`tools/output/analysis/findings.json`. CI uploads both as artifacts.

Analysis uses the rules selected in `PSScriptAnalyzerSettings.psd1`, and any
diagnostic fails the task, so warnings cannot pass silently. To reuse it elsewhere,
copy the settings, `tools/Invoke-RepositoryAnalysis.ps1`, the `Analyze` task and the
workflow job. Branch protection must be configured separately.

Passing checks use synthetic inputs and mocked APIs. They do not verify live PSU,
browser rendering, Graph or CMDB behavior.

Contributions are licensed under [MPL-2.0](LICENSE).
