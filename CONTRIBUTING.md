# Contributing

Code contributions are limited to invited collaborators. Public pull requests
are not accepted. Public participation is intended to focus on feature requests
and bug reports; the intake location is still to be decided.

Agents: follow [AGENTS.md](AGENTS.md) before working. Changes to the running PSU instance require separate authorization; its managed Repository is read-only for agents.

## Workflow

1. Agree on a bounded issue with an outcome and acceptance criteria. Add it to the repository's GitHub Project and set its status to **In Progress** when work starts.
2. Branch from current `main`. Make the scoped change and run appropriate checks.
3. Open a PR linking the issue with `Closes #<issue-number>`. Describe the resulting behavior, verification, and any remaining limitations.
4. Review, then squash merge when authorized. Set the Project item to **Done** and remove the work branch.

`main` requires PRs and successful **Pester (full suite)** and **PSScriptAnalyzer**
checks from GitHub Actions. Direct pushes, force pushes, and branch deletion are
blocked. Required reviewer approvals start at zero to support a solo workflow.

## Tests and build tasks

Use PowerShell 7.4 or higher on Windows. Build dependencies are pinned in
`tools/BuildDependencies.psd1`. To install those versions for the current user,
run this explicitly when setting up a contributor environment:

```powershell
$dependencies = Import-PowerShellDataFile ./tools/BuildDependencies.psd1
foreach ($dependency in $dependencies.GetEnumerator()) {
    Install-PSResource -Name $dependency.Key -Version $dependency.Value -Repository PSGallery -Scope CurrentUser -TrustRepository
}
```

`Install-PSResource` is provided by Microsoft.PowerShell.PSResourceGet. The
installation command trusts PSGallery for this operation; it does not change
the repository's saved trust setting. Build tasks require installed dependencies
and do not install them automatically.

Run commands from the repository root in a fresh PowerShell session. Import the
pinned InvokeBuild version, then use the same tasks that CI runs:

```powershell
$dependencies = Import-PowerShellDataFile ./tools/BuildDependencies.psd1
Import-Module InvokeBuild -RequiredVersion $dependencies.InvokeBuild
Invoke-Build                       # Full suite; equivalent to Invoke-Build Test
Invoke-Build Test -Suite Dashboards
Invoke-Build Test -Suite Dashboards,Data,Reports
Invoke-Build Analyze               # Static analysis; independent of -Suite
Invoke-Build Analyze,Test          # Both checks required before a PR
```

| Suite | Test locations |
| --- | --- |
| `All` (default) | Every repository `*.Tests.ps1` file, excluding `tools/output/`. Automatically includes new test locations. |
| `Data` | `modules/ParData/`, recursively. |
| `Reports` | `modules/ParReports/`, recursively. |
| `Dashboards` | `dashboards/`, recursively; these are offline composition and state tests. |
| `Factories` | `tools/factories/`, recursively. |
| `Tools` | Tests directly in `tools/`, including the test-task checks. |

Named suites may be combined; each test file runs once. `All` must be selected
alone. During development, select the changed area and any affected consumers
or dependencies. A dashboard-only presentation change can start with
`Dashboards`; changes spanning report or data behavior should also run `Reports`
or `Data`. Factory/exporter changes generally warrant `Factories`, `Data`, and
their affected report/dashboard consumers. Suite selection is explicit, not an
automatic dependency analysis. Run analysis and the full suite before every PR.

The task fails on failing tests, discovery errors, or an empty test selection.
Each run writes NUnit3 XML under `tools/output/tests/`, with a filename based on
the sorted selection (`all.xml`, `dashboards.xml`, or `dashboards-data-reports.xml`).
Rerunning that selection replaces its report. Reports are generated artifacts,
so `tools/output/` remains ignored by Git. GitHub Actions uploads reports from
the current run even when tests fail; they do not need to be committed.

GitHub Actions runs the full task for PRs targeting `main`, pushes to `main`,
and manual workflow dispatches on a Windows runner using PowerShell 7. The
workflow installs the pinned dependencies and saves the XML reports as the
`pester-results` artifact. These tests use synthetic inputs and mocked API
calls; a passing check does not verify live PSU, browser rendering, Graph, or
CMDB behavior. PSU deployment and synchronization are separate operations.

## Static analysis

`Invoke-Build Analyze` uses the pinned PSScriptAnalyzer version and the root
`PSScriptAnalyzerSettings.psd1`. It checks `.ps1`, `.psm1`, and `.psd1` files
throughout the repository, including `.universal/` and Pester tests, excluding
Git internals and generated `tools/output/` files. The default build still runs
Pester only; use `Analyze,Test` to run both checks locally.

The settings select eight built-in rules:

| Rule | Detects |
| --- | --- |
| `PSUseApprovedVerbs` | Function names with unapproved verbs. |
| `PSAvoidUsingCmdletAliases` | Aliases where explicit command names should be used. |
| `PSAvoidUsingEmptyCatchBlock` | Empty exception handlers. |
| `PSAvoidUsingInvokeExpression` | Use of `Invoke-Expression`. |
| `PSAvoidAssignmentToAutomaticVariable` | Assignment to automatic variables covered by the rule. |
| `PSAvoidUsingPlainTextForPassword` | Password parameters using plaintext types. |
| `PSAvoidUsingConvertToSecureStringWithPlainText` | Plaintext conversion through `ConvertTo-SecureString -AsPlainText`. |
| `PSMisleadingBacktick` | Whitespace after a backtick that defeats intended line continuation. |

`PSMisleadingBacktick` permits valid backtick continuation; this profile does not
ban continuation or ordinary backtick escapes. No custom rules or automatic
fixes are configured. These checks identify selected code patterns; they do not
prove security or live PSU compatibility.

Any unsuppressed diagnostic, including a warning or parse error, fails the task.
Findings include the source path, line, column, rule, severity, and message in
`tools/output/analysis/findings.json`; a clean run writes `[]`. CI runs analysis
as a separate job on the same triggers as Pester and uploads that report as
`psscriptanalyzer-results`, including when findings fail the check. A failure
before a report is produced remains a failed job and may have no artifact.

To reuse this check in another PSU repository, copy the settings, analysis
runner, and relevant pinned dependencies; add the `Analyze` task to its build
file and adapt the workflow job. Change `IncludeRules` to choose a different
baseline, and review the runner's exclusions for that repository's generated
files. Retain the task's explicit diagnostic failure check so warnings cannot
silently pass CI. The separate Pester job and its dependencies are optional for
consumers adopting analysis alone. Configure that repository's required status
checks separately; copying workflow YAML does not establish branch protection.

## Agent workflow skills

- [start-work](.agents/skills/start-work/SKILL.md): check whether local files match GitHub, then prepare a clean, current branch before an authorized task.
- [submit-work](.agents/skills/submit-work/SKILL.md): commit reviewed changes, push the work branch, and open a PR when authorized.
- [finish-work](.agents/skills/finish-work/SKILL.md): verify a PR merged, update local `main`, and remove its work branches.

Questions such as "are we synced to Git?" request a status check. They do not authorize editing, publication, or cleanup. An explicit request to start a task authorizes its branch preparation; publication and post-merge cleanup remain separate actions.

## Git reference

This is the command reference for all three skills; keep command syntax here. Replace placeholders and execute only the authorized phase. Stage only reviewed files belonging to the change. Stop on failed checks rather than continuing through the block.

```powershell
# 1. /start-work: inspect first; stop if staged, modified, or untracked files exist.
git status --short --branch
git fetch --prune origin
git switch main
git rev-list --left-right --count main...origin/main
# Stop if main has local-only commits. Fast-forward only, then require 0 0.
git pull --ff-only
git rev-list --left-right --count main...origin/main
git switch -c issue/<issue-number>-<short-description>

# 2. /submit-work: only after review and authorization to commit, push, and open a PR.
git status --short --branch
git diff --stat
git add <changed-files>
git diff --cached
git diff --cached --check
git commit -m "Describe the change" -m "Authored by PAR Codex"
git push -u origin HEAD
gh pr create --base main --title "Describe the change" --body-file <pr-body-file>
gh pr view <pr-number> --json url,state,baseRefName,headRefName,headRefOid

# 3. /finish-work: require a clean tree and confirm the matching PR is MERGED into main.
gh pr view <pr-number> --json url,state,baseRefName,headRefName,headRefOid,mergeCommit
git status --short --branch
git fetch --prune origin
git rev-parse <work-branch>
git ls-remote --heads origin <work-branch>
# Before deleting, require existing branch tips to match the merged PR's headRefOid.
git switch main
git rev-list --left-right --count main...origin/main
# Stop if main has local-only commits; require 0 0 after the fast-forward.
git pull --ff-only
git rev-list --left-right --count main...origin/main
git merge-base --is-ancestor <merge-commit> main
# Require success: the recorded merge commit must be part of local main.
# Skip remote deletion if GitHub already removed the branch.
git push origin --delete <work-branch>
git branch -d <work-branch>
# If -d refuses after a squash merge, -D is allowed ONLY after verifying the
# PR is merged and the local branch still matches its headRefOid, with no extra work.
git branch -D <work-branch>
git fetch --prune origin
git status --short --branch
git rev-list --left-right --count main...origin/main
git branch --list <work-branch>
git ls-remote --heads origin <work-branch>
```

After submission, verify the PR targets `main` and contains the intended commit, issue link, and attribution. Do not merge as part of submission. After cleanup, verify both work branches are absent and local `main` matches the freshly fetched remote. Update and verify the linked issue and Project status for the completed phase.

Explicitly note agent involvement in Git-related activity wherever a message or
description is available. For this project's designated Codex contributor, every
commit and PR description must include exactly `Authored by PAR Codex`, without
model or version values. Preserve the attribution in the squash commit message.
ADR-0009 defines the attribution convention.

Contributions are licensed under [MPL-2.0](LICENSE).
