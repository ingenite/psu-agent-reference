---
name: start-work
description: Check whether local files match GitHub or prepare a branch before changing repository files. Use for requests such as "are we synced to Git?", "are my files current?", "get the latest files", or starting a new implementation task. Status questions alone do not authorize edits.
---

# start-work

Read the repository's [AGENTS.md](../../../AGENTS.md) and [CONTRIBUTING.md](../../../CONTRIBUTING.md). Use the **/start-work** phase of CONTRIBUTING's Git reference for command syntax.

1. Identify the intended repository, task, and any linked issue. For a status question, inspect local changes, refresh remote references, and compare the current branch and local main with origin/main. Report differences in plain language and stop; do not change working files or create a branch. An explicit request to update local files permits a clean fast-forward, but does not imply a new task.
2. Before the first file addition, edit, or removal for a new task, require a clean working tree, including staged and untracked files. If it is dirty, report the files and stop task preparation. Never silently stash, discard, commit, or carry unrelated work into a new task.
3. Refresh origin and confirm local main can advance without a merge or rebase. Fast-forward main if needed, then verify it matches origin/main. If remote access fails, local main has unpublished commits, or histories diverge, stop before editing and explain what is unresolved.
4. Create a new issue branch from the verified main and update the agreed issue/Project status. If already continuing the same task on its prepared branch, inspect its changes and continue without creating another branch or demanding that its in-progress work be clean.
5. Report the branch and confirmed starting point, then perform the authorized task. This phase does not authorize committing, pushing, opening a PR, or merging.
