# Contributing

Contributions are currently limited to invited collaborators.

Agents: read [PROJECT-BRIEF.md](PROJECT-BRIEF.md) before working. Follow its implementation constraints and authorization boundaries. Changes to the running PSU instance require separate authorization; its managed Repository is read-only for agents.

## Workflow

1. Agree on a bounded issue with an outcome and acceptance criteria. Add it to the repository's GitHub Project and set its status to **In Progress** when work starts.
2. Branch from current `main`. Make the scoped change and run appropriate checks.
3. Open a PR linking the issue with `Closes #<issue-number>`. Describe the resulting behavior, verification, and any remaining limitations.
4. Review, then squash merge when authorized. Set the Project item to **Done** and remove the work branch.

`main` requires PRs. Direct pushes, force pushes, and branch deletion are blocked. Required reviewer approvals start at zero to support a solo workflow; required CI checks will be added as CI is established.

## Git reference

Replace placeholders before running these commands. Stage only files belonging to the change.

```powershell
git switch main
git pull --ff-only
git switch -c issue/<issue-number>-<short-description>

git add <changed-files>
git diff --cached
git diff --cached --check
git commit -m "Describe the change" -m "Authored by <agent> <model> <version>"
git push -u origin HEAD

gh pr create --base main --title "Describe the change" --body-file <pr-body-file>
```

Explicitly note agent involvement in Git-related activity wherever a message or description is available. Every agent-created commit and PR description must include `Authored by [agent] [model] [version]`, using the session's specified identity; for example, `Authored by PAR Codex Sol GPT-6.1`. Preserve the attribution in the squash commit message.

Contributions are licensed under [MPL-2.0](LICENSE).
