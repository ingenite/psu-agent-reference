# Repository Guidelines

Build realistic, idiomatic PowerShell Universal examples for AI agents and Windows administrators. Keep this repository self-contained; do not import sibling-project conventions.

## Project Structure & Module Organization

Before choosing file locations, read [README's directory guide](README.md#directory-structure). Separate presentation, orchestration, and reusable operations. Prefer PSU's integrated documentation for resource behavior; verify its source is versioned.

## Build, Test, and Development Commands

No build, server launcher, formatter, linter, or CI is configured.

- `pwsh -NoProfile -Command "Invoke-Pester -Path . -Output Detailed"`: run repository tests with Pester installed.
- `git diff --check`: check patch whitespace.

Do not run `tools/Initialize-SecretVault.ps1` as a routine check: it changes the current user's SecretStore configuration.

## Coding Style & Naming Conventions

Before writing PowerShell, read and follow the [runtime](docs/adr/0001-prefer-powershell-7.md), [naming](docs/adr/0002-standardize-powershell-names.md), and [implementation](docs/adr/0004-prefer-idiomatic-powershell.md) decisions. Explicit .NET techniques, custom JavaScript, and CSS require scoped owner approval unless already covered by an approved exception.

Use four-space indentation and descriptive variables, with plural collections and singular items. Limit comments to unusual implementations, version requirements, and production breadcrumbs.

## Command Discovery & Probe Scripts

Never guess command syntax or outputs. Before using new or unfamiliar PowerShell cmdlets, attempt local discovery with `Get-Help Unfamiliar-Cmdlet` or inspect output from a safe, authorized invocation using `Unfamiliar-Cmdlet | Get-Member`.

For PSU syntax, configuration, and behavior, consult vendor documentation through the configured `product-guides-reference` MCP. Verify version-specific assumptions against the installed environment.

When local discovery is unavailable or insufficient, write a probe script for the user to run. Save all probes in `tools/`; all project guidelines, including implementation and authorization constraints, apply.

Probes must export results using appropriate built-in PowerShell formats and commands: JSON, CSV, TXT, or XML. Write all output files to `tools/output/`, creating the directory when needed. Keep console output brief, identifying the result files; do not require multi-screen shell copy/paste.

## Testing Guidelines

Use sibling Pester tests with behavior-focused assertions and reusable setup. No coverage percentage is prescribed. Report exactly what checks exercised; distinguish isolated tests from live PSU or external-system verification.

## Commit & Pull Request Guidelines

Before editing, use [start-work](.agents/skills/start-work/SKILL.md). For reviewed changes, use [submit-work](.agents/skills/submit-work/SKILL.md); after merge, use [finish-work](.agents/skills/finish-work/SKILL.md). Follow [CONTRIBUTING.md](CONTRIBUTING.md) for Git commands and [ADR-0003](docs/adr/0003-define-par-identity.md) for attribution.

## Agent & Deployment Boundaries

Direct requests authorize scoped work; installation, commits, pushes, and server configuration require separate authorization. PSU's managed Repository is read-only, including indirect writes. Before deployment, synchronization, or credential work, read and follow [ADR-0005](docs/adr/0005-develop-in-source-deploy-through-git.md).
