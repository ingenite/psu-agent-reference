# Contributing

Contributions are currently limited to invited collaborators.

Agents: read [AGENTS.md](AGENTS.md) before working and use the appropriate repository skill below. Changes to the running PSU instance require separate authorization; its managed Repository is read-only for agents.

## Workflow

1. Agree on a bounded issue with an outcome and acceptance criteria. Add it to the repository's GitHub Project and set its status to **In Progress** when work starts.
2. Branch from current `main`. Make the scoped change and run appropriate checks.
3. Open a PR linking the issue with `Closes #<issue-number>`. Describe the resulting behavior, verification, and any remaining limitations.
4. Review, then squash merge when authorized. Set the Project item to **Done** and remove the work branch.

`main` requires PRs. Direct pushes, force pushes, and branch deletion are blocked. Required reviewer approvals start at zero to support a solo workflow; required CI checks will be added as CI is established.

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
git commit -m "Describe the change" -m "Authored by <agent-designation> <model-designation>"
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

Explicitly note agent involvement in Git-related activity wherever a message or description is available. Every agent-created commit and PR description must include `Authored by [agent designation] [model designation]`, using the session's verified agent and model labels; for example, `Authored by PAR Codex Sol GPT-6.1`. Preserve the attribution in the squash commit message.

Contributions are licensed under [MPL-2.0](LICENSE).
