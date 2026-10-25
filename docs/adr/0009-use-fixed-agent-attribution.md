# ADR-0009: Use fixed agent attribution

## Status

Accepted; supersedes the attribution portion of ADR-0003.

## Context

Attribution identifies the contributor responsible for agent-created Git work.
Dynamic model and release values add session-specific metadata to that workflow.
The owner has chosen a fixed designation for this project's Codex contributor.

## Decision

Use exactly `Authored by PAR Codex` in this contributor's commit messages and PR
descriptions. Preserve it in the squash commit message. Do not append model,
variant, or version values or require their discovery before Git work.

Other agents and downstream consumers use their own contributor designation
without model or release metadata. `PAR Codex` remains reserved for this project's
designated Codex contributor.

## Consequences

Agent involvement remains explicit and consistent across sessions. Model and
release metadata are no longer part of the repository's attribution convention.
