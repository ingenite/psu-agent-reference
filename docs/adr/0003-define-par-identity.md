# ADR-0003: Define PAR identity

## Status

Accepted

## Context

Project commands need a recognizable identity that distinguishes them from vendor
commands. Agent attributions also need to distinguish this project's contributor
from agents used by downstream consumers.

## Decision

`PAR` abbreviates the name of this project: **PSU Agent Reference**
Use `Par` in PascalCase identifiers.

Use `PAR` / `Par` as the noun prefix for custom module commands, for example
`Get-ParConfiguration`. Reserve the vendor's `PSU` prefix for vendor commands.
General-purpose tools do not need the project prefix; see
[ADR-0002](0002-standardize-powershell-names.md).

Use `PAR Codex` only for this project's designated Codex contributor. Other agents
use their own agent designation. Retain the attribution format
`Authored by [agent designation] [model designation]`. The agent designation
identifies the contributor, such as `PAR Codex`; the model designation includes
its variant and release, such as `Sol GPT-6.1` (model ID `gpt-6.1-sol`). Use verified
session metadata or the owner's explicit session identification. If the model
designation is unavailable, record `unknown`; do not guess or block the work.
Preserve that attribution in the squash commit, as required
by [Contributing](../../CONTRIBUTING.md).

The contribution standards apply to anyone working in this repository, regardless
of the agent they use. Downstream consumers adapting examples identify their own
agent and model designations in their attributions.

## Consequences

Readers can identify project-owned commands without confusing them with PSU's
commands. Attributions identify both the project agent and the model used, so
future contributions remain distinguishable.
