# ADR-0000: Record architecture decisions

## Status

Proposed

## Context

Code shows what the project does, but the reasons behind its design can be lost
between contributors and sessions. Architecture decision records (ADRs) preserve
one consequential choice, its reasons, and its trade-offs alongside the code.

## Decision

Use a lightweight version of [Nygard's format](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions):
a title, Status, Context, Decision, and Consequences.

- Store records in `docs/adr/NNNN-short-descriptive-title.md`, numbered sequentially
  from `0000`.
- Record choices that shape project structure, execution boundaries, dependencies,
  or integration patterns. Routine implementation details stay in the code.
- Keep each record focused on one decision, with short explanations of the
  relevant constraints and trade-offs.
- Start with `Proposed`; change to `Accepted` when the project owner approves,
  or `Rejected` if the proposal is declined.
- When replacing an accepted decision, add a new record and mark the earlier one
  `Superseded`, linking both records. Preserve the earlier reasoning.

## Consequences

Humans and agents can understand the reasoning behind the implementation without
access to earlier conversations. Records add a small maintenance cost, so they
are reserved for decisions whose reasoning will remain useful.
