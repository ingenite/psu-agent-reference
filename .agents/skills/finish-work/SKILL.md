---
name: finish-work
description: Update local files and remove the completed work branches after a pull request merges. Use for "the PR merged, clean up", "finish this change", or "bring my files up to date after the merge". This skill verifies merge state and does not merge or delete unfinished work.
---

# finish-work

Follow applicable repository instructions. If not already loaded, read [AGENTS.md](../../../AGENTS.md); consult the **/finish-work** phase of [CONTRIBUTING's Git reference](../../../CONTRIBUTING.md#git-reference) for command syntax.

1. Confirm cleanup is authorized and identify the exact PR and work branch. Verify live GitHub state says the PR merged into main; record its head commit and merge commit. An open or closed-but-unmerged PR is not ready for cleanup. A status question alone requests inspection, not deletion.
2. Require a clean working tree, including staged and untracked files. Refresh origin and inspect both work-branch tips. Each existing tip must match the merged PR's head commit; stop if additional commits, local changes, or a reused branch name could contain unfinished work. Never stash, discard, or delete that work.
3. Switch to main and fast-forward from origin/main. Stop on unpublished local main commits, divergence, or failed remote access. Verify main matches the refreshed remote and contains the recorded merge commit before deleting any branch.
4. Remove the matching remote work branch if it still exists, then remove the local work branch. A squash merge may prevent ordinary local deletion: only use CONTRIBUTING's documented fallback after rechecking the merged PR and exact local tip. Already-removed branches are a successful, repeatable condition, not a reason to recreate them.
5. Refresh and verify: main is checked out and clean, main matches origin/main, and both work branches are absent. Verify the linked issue is closed and the Project item is Done, updating them when required by the authorized workflow. Report observed results and any incomplete step.
