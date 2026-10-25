# Example prompts

Give your agent access to this repository, then use or adapt one of these prompts.
These prompts will evolve as resources are shipped. The documentation index and
command help provide the technical details.

## Explain and try the report

> Read docs/README.md and docs/errata.md, then inspect the Intune report example
> and its command help. Explain what I can run today, which dependencies I need,
> and what the results mean. Give me the commands to try it locally from the
> repository root. Do not execute them or change files.

Expected result: a short explanation, prerequisites, and commands with enough
context to recognize the expected report results.

## Plan an adaptation

Replace `<target project>` with the location of your project.

> Read docs/README.md and docs/errata.md. Inspect this repository's Intune
> reporting example and `<target project>`. Propose the smallest adaptation needed
> to use the report there. Identify reusable files, required configuration, and
> verification steps. Distinguish this repository's contributor rules from
> requirements of the reusable example, and follow the target project's own
> instructions. Present the proposal before editing or changing either runtime.

Expected result: a bounded implementation proposal that identifies dependencies,
target-specific decisions, and what would need further verification.
