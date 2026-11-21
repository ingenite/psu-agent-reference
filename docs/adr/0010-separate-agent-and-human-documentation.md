# ADR-0010: Separate agent and human documentation

## Status

Accepted; supersedes ADR-0008.

## Context

ADR-0008 kept one documentation set for agents and humans and asked maintainers
to update errata whenever verification changed. In practice each session added a
paragraph describing what it had checked. Errata, setup guides, report guides and
benchmark write-ups grew long and repeated what code, command help and evidence
files already state. Long documents cost agents context and make humans skim.

Agents read the repository; most of what a guide says about *what* code does they
can infer from the code and its help. What they cannot infer is *why* a choice was
made and *where* the evidence is. Humans want short, plain explanations and rarely
need parameter detail. The GitHub Wiki is now available for that audience.

## Decision

Repository documentation serves agents. Keep it short and use it as a signpost:
state the reason for a choice and point at the code, help, test or evidence file
that shows it. Do not restate behavior that command help or code already makes
clear.

The GitHub Wiki serves humans: overviews, walkthroughs, example prompts and result
summaries in plain language. Wiki pages explain and link; they never own command
contracts, decisions or verification gaps. Draft substantial wiki changes in a
`wiki/` folder on a branch so they can be reviewed in a PR, publish them after the
merge, then remove the folder.

Every document answers *why* before *what*.

| Information | Owner |
| --- | --- |
| Purpose, safety warning, reference environment | Root README |
| Routing for agents and humans | `docs/README.md` |
| Directory reference | `docs/directory-guide.md` |
| Parameter, input, output and side-effect contracts | PowerShell command help |
| Non-obvious implementation reasons | Comments beside the code, or a short adjacent README |
| Open verification gaps | `docs/errata.md` |
| Durable choices and reasons | ADRs |
| Agent behavior | `AGENTS.md` |
| Contribution workflow; Git command syntax | `CONTRIBUTING.md`; workflow skills |
| Experimental results | `tools/benchmarks/` |
| Human guides and prompts | GitHub Wiki |

Errata lists open gaps only, one table row each, with a pointer to the related
evidence. Delete a row when the gap closes. Record what a session verified in its
PR description, not in errata. A Pester test caps errata length and the set of
entries directly under `docs/`, so growth needs a deliberate decision.

## Consequences

Agents load less text and find evidence faster. Humans get a separate, readable
entry point. Wiki content is not covered by repository tests or branch protection,
so it may drift; it must link to the repository rather than copy contracts. Past
verification narratives remain available in Git history and PR descriptions.
