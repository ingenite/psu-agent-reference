# ADR-0003: Define PAR identity

## Status

Accepted

The attribution portion is superseded by [ADR-0009](0009-use-fixed-agent-attribution.md).
The project and command naming decisions remain accepted.

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

Use `PAR Codex` only for this project's designated Codex contributor. The earlier
attribution decision also identified the model and release to distinguish agent
contributions. ADR-0009 replaces that requirement with fixed agent attribution.

The contribution standards apply to anyone working in this repository, regardless
of the agent they use. Other agents and downstream consumers identify their own
contributors rather than adopting this project's designated agent identity.

## Consequences

Readers can identify project-owned commands without confusing them with PSU's
commands. Attributions distinguish the project contributor from downstream
contributors without requiring model metadata under the current convention.
