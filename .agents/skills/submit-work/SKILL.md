---
name: submit-work
description: Submit a completed, user-reviewed change to GitHub as a pull request. Use for "send these changes to GitHub", "ready to submit", "commit and push", or "open a PR". Preparing submission details alone does not authorize publication, and this skill does not merge.
---

# submit-work

Follow applicable repository instructions. If not already loaded, read [AGENTS.md](../../../AGENTS.md); consult the **/submit-work** phase of [CONTRIBUTING's Git reference](../../../CONTRIBUTING.md#git-reference) for command syntax. Follow any attribution rules linked there.

1. Inspect the current branch, all staged and unstaged changes, untracked files, and the task's issue. Confirm this is the intended work branch, not main, and identify the exact files belonging to the reviewed task. Preserve unrelated work.
2. Run appropriate checks and review the complete intended patch, including new files and anything already staged. If checks fail or the patch needs material changes, resolve them within scope and return the changed result for review before publication.
3. Require the user's review and authorization for the requested submission actions. When asked only to prepare, present the commit message, PR title/body, checks, and limitations, then stop. A request only to commit does not authorize a push; a request only to push does not authorize opening a PR. Reuse approval already given for this reviewed change.
4. Perform only the authorized actions in order: stage the reviewed files, inspect the staged patch, commit with actual attribution, push the work branch, and open the linked PR against main. Do not include unrelated staged files. Check for an existing matching PR before creating one; resume from verified state rather than duplicating completed actions.
5. Verify the published branch and PR match the reviewed commit, issue link, base, and attribution. Report the commit, PR link, verification evidence, and remaining limitations. Stop before merge; merge and cleanup require their own authorization.
