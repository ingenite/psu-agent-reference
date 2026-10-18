# ADR-0002: Standardize PowerShell names

## Status

Accepted

## Context

Consistent names make scripts and commands easier to discover and their purpose
easier to predict. PowerShell's established naming conventions provide a shared
vocabulary for contributors and consumers.

## Decision

- Name executable `.ps1` scripts and functions `Verb-Noun`, using PascalCase and a
  descriptive singular noun. This includes private and local helper functions.
- Use only approved PowerShell verbs available through `Get-Verb`. Choose the verb
  that describes the operation.
- Files whose names are prescribed by PSU, PowerShell, or another required
  framework retain those names.
- Prefix custom module command nouns with `Par`, as defined in
  [ADR-0003](0003-define-par-identity.md), for example `Get-ParConfiguration`.
  General-purpose tools can retain platform-neutral names such as
  `New-JwtSigningKey.ps1`.
- Use descriptive PascalCase module names. Match the root `.psm1` and manifest
  `.psd1` basenames to the module name; a module named `Par` would use `Par.psm1`
  and `Par.psd1`.
- Name sibling Pester files `<Name>.Tests.ps1`, preserving the name of the script
  or module they test, for example `New-JwtSigningKey.Tests.ps1`.

## Consequences

Public commands and internal helpers follow the same naming discipline. Module
names identify a collection of commands, while command names describe an action
on a resource. Contributors check unfamiliar verbs with `Get-Verb` before naming
a script or function.
