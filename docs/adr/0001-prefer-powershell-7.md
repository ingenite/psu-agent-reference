# ADR-0001: Prefer PowerShell 7

## Status

Accepted

## Context

PowerShell 7 is actively developed, supports Windows, Linux, and macOS, and offers
a richer feature set than Windows PowerShell 5.1. Microsoft's
[migration guidance](https://learn.microsoft.com/en-us/powershell/scripting/whats-new/migrating-from-windows-powershell-51-to-powershell-7)
describes its capabilities and compatibility options. Devolutions also
[recommends PowerShell 7 as the default PSU environment](https://docs.devolutions.net/powershell-universal/config/environments#powershell-7).

## Decision

Use PowerShell 7 (`pwsh`) by default for repository development, tools, and PSU
workloads. Use Windows PowerShell 5.1 sparingly when a dependency or compatibility
requirement calls for it, with a brief explanation near the affected code.

Declare the minimum PowerShell version when newer features require it, and briefly
comment syntax or commands specific to PowerShell 7. If a file would contain more
than three such comments, consolidate them into a brief header comment block.

## Consequences

Contributors need PowerShell 7 and can use its newer features without maintaining
general Windows PowerShell compatibility. Cross-platform usage is possible, but
individual scripts and dependencies may still require Windows. Limited Windows
PowerShell exceptions preserve access to dependencies that require that runtime.
