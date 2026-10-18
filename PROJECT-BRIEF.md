# psu-agent-reference — Project Brief

This briefing records the project owner's decisions from the initial workshop. It is the handoff for a dedicated working session. It establishes goals and constraints; it does not prescribe a finished feature set or authorize every possible setup, deployment, or Git operation.

## Purpose and audience

Build a public, fully open-source repository that defines a working PowerShell Universal (PSU / PSUniversal) instance containing realistic demonstration functionality.

The primary audience is LLMs and the agents using them. The repository should provide credible, idiomatic PowerShell and PSU implementations that agents can inspect, understand, adapt, and reproduce. Humans remain an important audience, particularly Windows and Microsoft platform administrators whose practical PowerShell experience may exceed their familiarity with software development terminology.

Suggested project description:

> A living PowerShell Universal reference for AI agents and the people directing them.

The implementation is the educational resource. This is not a basic PowerShell syntax tutorial. Favor useful implementations, clear structure, meaningful verification, and documentation explaining the context needed to use them correctly.

The project should stay close to the work of Microsoft and Windows administrators: Azure, Entra, Microsoft 365, SharePoint, SCCM/MECM, Defender, and related administrative automation. These are audience and scenario boundaries, not requirements to integrate with all those products.

## Working relationship and authority

The owner acts as project manager, mentor, and reviewer. The agent handles implementation within the requested scope. Do not assume a global mentoring mode in which the owner must perform every implementation step.

Treat direct requests as scoped authorization. Implementing code does not automatically authorize installation, system configuration, committing, pushing, publishing, or unrelated changes. A request for a command is a request to present it, not execute it.

Keep explanations practical and concise. Present material design decisions and ask for decisions where the explicit exception rules below apply. Routine choices within an authorized task can proceed without repeated confirmation.

### Agent attribution

Explicitly note agent involvement in Git-related activity wherever a message or description is available. Agent-created commit messages and pull request descriptions must include `Authored by [agent] [model] [version]`, using the identity specified for that session. For example: `Authored by Codex Sol GPT-6.1`.

## GitHub workflow and license

Host the public project at `ingenite/psu-agent-reference` on GitHub under the Mozilla Public License 2.0 (`MPL-2.0`). Use GitHub Issues and a repository-linked Project to track work. Contributions are initially limited to invited collaborators, and changes to `main` must go through PRs and merges. See [CONTRIBUTING.md](CONTRIBUTING.md) for the working procedure.

## Repository and isolation

- Project name and working repository: `psu-agent-reference`, at `C:\repos\psu-agent-reference`.
- Keep the project self-contained. Do not import requirements, conventions, instructions, dependencies, or implicit context from the sibling OpsPortal or Roadmap projects.
- Agent resources must make sense to someone who does not have the owner's other repositories, private memory, personal paths, or conversation history.
- Keep durable project guidance in the repository. This briefing can inform a future repository-local `AGENTS.md`; it is not a request to copy the entire briefing into every agent resource.

## Local PSU environment — owner-provided context

At the time of the workshop, the owner described:

- A personal local PSU installation, using the standard MSI installation and Kestrel.
- Address: `http://localhost:5000`.
- SQLite storage, with local and Devolutions authentication only.
- A developer license associated with the owner's personal Devolutions account.
- Databases and PSU's managed Repository directory under `C:\ProgramData\UniversalAutomation`.
- Application settings at `C:\ProgramData\PowerShellUniversal\appsettings.json` and logs under `C:\ProgramData\PowerShellUniversal\Logs`.
- Little configuration beyond testing. Existing test artifacts may require cleanup; this is not authorization to delete them.
- No enterprise or paid-work association. The owner states the installation contains no sensitive data; remaining test code is trivial.

Verify the installed PSU and PowerShell versions and relevant configuration before relying on version-specific behavior. The environment description is owner-provided context, not an independently verified inventory.

### Strict boundary: PSU-managed Repository is read-only

`C:\ProgramData\UniversalAutomation\Repository` is READ-ONLY FOR AGENTS.

Agents may inspect it, including to confirm that a merge or other expected Git change arrived through PSU's configured Git synchronization. Agents must not create, edit, delete, move, or otherwise modify files there. Do not bypass this restriction through PSU's UI, APIs, scripts, or another indirect write mechanism.

Implement changes in `C:\repos\psu-agent-reference`. Delivery to the running instance should use the intended Git/PSU synchronization workflow once that workflow has been established and the relevant operation is authorized. Do not assume Git synchronization is already configured.

## Implementation constraints

### PowerShell and exception approval

Use idiomatic PowerShell: native cmdlets, operators, pipelines, and straightforward expressions appropriate to the actual workload.

.NET-specific syntax and implementation techniques are prohibited unless the owner explicitly authorizes the particular use after hearing the argument for it. Before introducing such an approach, explain the concrete requirement, the idiomatic PowerShell alternative, and why the exception is warranted; then wait for the owner's decision. Existing .NET usage is not permission to introduce more. Hypothetical scale, unmeasured performance claims, or convenience are not authorization.

Custom JavaScript and CSS require the same prior argument and explicit human authorization, including embedded snippets. PSU accepting those languages does not grant permission to use them.

If a feature appears to require an exception, surface that decision before implementing the exception. Do not quietly relax these boundaries.

### Naming, readability, and comments

- Code should communicate its behavior through clear names and structure.
- Collection variables are plural; individual items are singular.
- Use descriptive variable names. Avoid single-character names and opaque abbreviations.
- Preferred shape: `$processes = Get-Process` and `foreach ($process in $processes)`.
- Comments are limited to unusual implementations that need explanation and intentional sample production implementations or integration breadcrumbs.
- Do not narrate ordinary code with comments. The primary audience can generally understand the code without them.

### Documentation

Use PSU's integrated documentation GUI/features for approximately 99% of code and script documentation wherever those features are available.

Verify how that documentation is stored and versioned so its source remains available to agents reading the repository. Keep repository setup, contribution, and agent instructions in their appropriate locations. Avoid maintaining duplicate explanations of the same behavior.

### Structure and reuse

Demonstrate separation of concerns through the implementation: presentation, orchestration, reusable operations, and external operations should have understandable responsibilities.

Use a PowerShell module for reusable commands. Look beyond convenience helpers for primitive or generic operations that genuinely support multiple scenarios. Let actual needs establish the abstractions; do not build a speculative framework or impose reuse before there is a useful shared responsibility.

## Demonstrations and external systems

Demonstrations should exercise real PSU behavior while keeping external dependencies minimal. Building substantial mock infrastructure or wiring up live enterprise systems would distract from the primary goal.

An external integration may be a small, explicit extension point. For example, a workflow might invoke a script that produces output and contains a production breadcrumb showing where `New-ADUser` could be added. The owner's rough allowance for an inexpensive integration detour was around 1–5 lines, not permission to develop a complete external integration.

The following were brainstorming examples, NOT committed requirements:

- Script automations demonstrating relevant `New-PSUScript` parameters.
- A dashboard consuming PSU APIs in a way analogous to a frontend consuming a backend or third-party service.
- An onboarding stepper invoking a script such as `Create-NewEmployee`.

No coherent fictional enterprise, mock directory service, simulated backend, or finished feature catalog has been agreed. Select concrete scenarios incrementally.

## Testing and CI

Pester and CI are part of the engineering discipline, not optional polish at the end.

Test behavior that should and can be tested reliably. Use meaningful assertions and reuse suitable test support rather than duplicating setup. Do not add tests merely to mirror the implementation or inflate coverage.

Establish appropriate automated PowerShell checks and Pester execution as the project takes shape. Decide how PSU-specific behavior can be validated based on the actual installation and available automation.

Report evidence accurately: static checks, isolated tests, mocked external operations, and live PSU verification establish different things. State what was exercised and what remains unverified. Do not claim a test of a placeholder proves an actual AD, Entra, or other external integration works.

CI provider, runner arrangement, detailed checks, and live-instance automation have not yet been selected.

## Reusable agent resources and AI collaboration

A secondary or tertiary output may be generic, distributable agent resources: skills, `AGENTS.md` guidance, and potentially curated actual session exports or excerpts.

These should help administrators use AI effectively: establish context, bound a task, set authorization limits, correct assumptions, review changes, and verify outcomes.

Be mindful of current OpenAI best practices and relevant new capabilities as these resources are created or revised. Consult current official documentation when a design depends on product behavior; do not freeze assumptions from an old session.

Keep resources lean and economical with context:

- Concise, actionable repository instructions.
- Focused skills with clear activation criteria and scope.
- Supporting references loaded when needed.
- Minimal duplication between instructions, skills, and documentation.
- Reusable guidance separated from instance-specific details.

Skills should emerge from useful workflows that have actually been exercised. Curated sessions remain an option, not a required deliverable. If used, select exchanges that demonstrate consequential guidance, corrections, decisions, and verification, with enough context to understand the resulting code or commit.

Official guidance consulted during the workshop:

- [Project instructions with AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [Build skills, including progressive disclosure](https://learn.chatgpt.com/docs/build-skills)

## Demonstration credentials

Values supplied by the project owner in prompts, or explicitly designated for inclusion in tracked files, may resemble passwords, secrets, tokens, or API keys. The owner states these are non-sensitive demonstration values, unconnected to live systems, and acceptable for public disclosure.

Preserve and use them as directed. Their format alone is not grounds to redact them, exclude them from Git, request rotation, or interrupt the task. This designation does not automatically extend to values independently discovered elsewhere in the environment.

## Vendor documentation

The owner intends future project sessions to have a Devolutions documentation MCP available:

```powershell
codex mcp add product-guides-reference --url 'https://docs.devolutions.net/~gitbook/mcp'
```

Documentation endpoint: `https://docs.devolutions.net/~gitbook/mcp`.

The command is context for the intended documentation integration. Its presence here is not evidence that it has been run or that the MCP is available, and is not an instruction to install it without a request.

## Opening work for the dedicated session

The concept is sufficiently established to begin. Start with this brief and applicable repository guidance, inspect the working tree, and perform the read-only discovery needed to identify the actual environment.

Practical decisions still to settle:

1. Installed PSU/PowerShell versions and available integrated documentation features.
2. Existing PSU configuration, repository state, and test artifacts; any cleanup needs a defined scope.
3. PSU synchronization arrangement with the GitHub repository; synchronization is not yet configured.
4. Initial implementation structure and concise project-local agent instructions.
5. One small, useful implementation scope that establishes module, documentation, Pester, and CI conventions.

Do not mistake the brainstorming examples for an approved backlog. The opening session should turn the agreed direction into a concrete initial scope and then implement within the owner's authorization.
