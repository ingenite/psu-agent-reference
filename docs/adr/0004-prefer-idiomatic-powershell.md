# ADR-0004: Prefer idiomatic PowerShell

## Status

Accepted

## Context

This reference should be readable and maintainable by PowerShell practitioners.
Native PowerShell patterns keep implementation choices familiar and inspectable.
Other implementation techniques can be useful, but their use should be deliberate.

## Decision

Use native cmdlets, operators, pipelines, and straightforward expressions suited
to the actual workload.

Always ask the owner before introducing or extending explicit .NET APIs or
specialized types, custom JavaScript, or custom CSS, including embedded snippets,
unless an explicit owner-approved exception covers the use. Explain the concrete
requirement, the idiomatic PowerShell alternative, and why an exception is
warranted. Hypothetical scale or unmeasured performance gains do not justify an
exception.

This rule applies to implementation, tests, temporary scripts, and one-off
verification commands.

Exceptions must identify the approved technique, intended use, and scope:

- **File:** record the approval in a comment directly preceding the exception.
  It applies only to that file.
- **Session:** the owner explicitly authorizes the technique in a prompt for the
  duration of that session.
- **Repository:** record the approved exception in an ADR or `AGENTS.md`.

These restrictions govern additions and extensions; they do not mandate removal
or refactoring of existing code. Session approval expires when the session ends,
but approved code may remain. New uses or extensions in later sessions require
an applicable exception; session approval does not become permanent file approval.

Ordinary PowerShell type annotations and casts, and familiar instance methods such
as `.Trim()`, do not require exception approval. Existing .NET, JavaScript, or CSS
usage does not establish an exception. Do not infer permission beyond an
exception's explicit scope.

## Consequences

Contributors favor familiar PowerShell patterns and explain unusual implementation
choices before adding them. Some capabilities require an explicit exception,
keeping the owner involved in decisions that expand the implementation approach.
