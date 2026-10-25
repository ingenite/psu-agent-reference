# ADR-0006: Standardize shared PSU configuration

## Status

Accepted

## Context

PSU resources can consume shared configuration while reusable PowerShell modules
also need to work outside PSU. Names and ownership must remain predictable without
making every local invocation depend on PSU registration commands.

## Decision

- Register project-owned shared PSU variables in `.universal/variables.ps1`.
- Use `PAR_` followed by a descriptive PascalCase name, such as `PAR_FixturePaths`.
  This prefix applies to shared PSU variables, not ordinary local variables.
- Declare scope and purpose in the registration. Consumers must account for the
  variables included by their PSU execution environment; registration alone does
  not prove availability in every resource.
- Keep non-secret configuration separate from credentials. Do not place runtime
  secrets in versioned variable values or require a contributor's credential store.
- Let each reusable module document its configuration inputs, precedence,
  validation, and behavior outside PSU. Defaults are appropriate when meaningful
  for that module; a missing required value must not silently select a live system.

`PAR_FixturePaths` is non-secret configuration. Its current global scope,
hashtable keys, and import-time precedence are part of ParData's configuration
contract, not requirements for every future shared variable or module.

## Consequences

Agents and administrators can identify project configuration without treating
every PowerShell variable as a PSU resource. Modules remain usable independently,
and new sources can define the configuration they actually require.
