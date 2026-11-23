# ADR-0011: Persist server security configuration in the database

## Status

Accepted

## Context

ADR-0005 delivers resources through pull-only (`OneWay`) Git synchronization, which
makes the admin console and Management API read-only for repository-backed
resources. Authentication methods and roles are different from apps or scripts:
each server needs its own (a public demonstration server and a private
development instance should not share login rules), and administrators need to
change them in the console without a pull request.

PSU's `Data:Persistence:<Type>` setting can move a resource type out of the
repository into the database. The vendor documentation gives examples (`Workflow`,
`Schedule`, `ScheduleParameter`) but no complete list of valid types.

## Decision

On servers synchronized from this repository, set `Data:Persistence` to `Database`
for `AuthenticationMethod` and `Role`, using app settings or the equivalent
environment variables. The repository does not version authentication or role
configuration. Every other resource type stays repository-backed under ADR-0005.

A type key is the configuration type name PSU logs at startup as
`Reading configuration for <Type>`. Moving another type to the database requires
updating this decision.

## Consequences

Each server keeps its own login and role rules, and they stay editable in the
admin console while the rest of the console is read-only. This was observed on a
Git-synchronized PSU 2026.3 server. These settings are not reviewed in Git, so
the database backup now includes security configuration, and every new server must
be configured deliberately. A repository `authentication.ps1` or `roles.ps1` is
ignored on servers that follow this decision.
