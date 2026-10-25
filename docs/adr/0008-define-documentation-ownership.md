# ADR-0008: Define documentation ownership

## Status

Accepted

## Context

This reference primarily serves agents, with administrators directing their use
and reviewing the result. Separate human and agent manuals would duplicate facts.
The early project brief, README, and feature guides have accumulated overlapping
policy and reference material.

## Decision

Maintain one documentation set in plain, precise language. Use explicit command
names, requirements, inputs, outputs, and examples so both audiences can find the
facts needed for a task.

Assign each kind of information one authoritative home:

| Information | Owner |
| --- | --- |
| Purpose, current stage, reference environment, and adoption entry point | Root README |
| Task-oriented table of contents | `docs/README.md` |
| Curated requests humans can give their agents | `docs/prompts.md` |
| Directory reference | `docs/directory-guide.md` |
| Parameter, input, output, error, and side-effect contracts | PowerShell command help |
| Composition, configuration, adoption, and interpretation | Scenario and setup guides |
| Known limitations and verification gaps | `docs/errata.md` |
| Durable choices and reasons | ADRs |
| Required agent behavior and reference routing | `AGENTS.md` |
| Contribution procedure and Git syntax | `CONTRIBUTING.md` and focused workflow skills |

Keep the root README short and direct: explain what the instance is, how to use
it, give humans introductory prompts for their own agents, and summarize the
reference test environment and its dependencies. Make the prohibition on syncing
this repository into production explicit. Resource and task
inventories belong in the documentation index. Keep resource-specific prompts in
`docs/prompts.md`; introductory prompts should not repeat technical reference.

Use familiar PowerShell help sections where applicable: Synopsis, Description,
Parameters, Inputs, Outputs, Examples, and Notes. Scenario guides can use
Requirements, Configuration, Examples, Interpretation, and Verification. Omit
sections that add no useful information.

For PSU resources such as scripts and endpoints, prefer PSU's resource-facing
documentation where supported, with its source versioned in the repository.
Verify the association and rendering before relying on the UI. This preference
applies to PSU resources, not all project documentation, and does not prescribe a
percentage. Do not maintain a separate explanation in the UI or require PSU
access to read the reference.

Idiomatic PowerShell help headers and external reference documents are appropriate
homes for documentation. Keep implementation comments meaningful and local to
unusual behavior, version requirements, or integration breadcrumbs. Do not hide
extended usage instructions or resource documentation among implementation comments.

Keep navigation links concentrated in the documentation index. Use other internal
links and external references sparingly, when they provide necessary navigation
or establish a consequential claim. Prefer stable file-level links; avoid routine
cross-linking and duplicated link lists. Plain command names and ADR numbers can
identify a dependency without adding another link.

Keep command behavior and immediate operational consequences beside the command.
Record broader evidence gaps in errata, and route readers there through the
index and agent guidance. Update errata when verification changes; test commands
in guides describe how to verify, not proof that verification occurred.

Retire the bootstrap project brief after preserving its enduring guidance in
the appropriate owners. Git history preserves the workshop record.

## Consequences

Humans can assess the project quickly and delegate deeper exploration through
curated prompts. Agents load the references relevant to their task. Documentation
has fewer competing authorities and fewer links to repair during early churn.
Maintainers must update the owning reference and errata as behavior and evidence
change.
