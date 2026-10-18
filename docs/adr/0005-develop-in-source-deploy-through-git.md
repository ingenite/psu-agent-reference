# ADR-0005: Develop in source; deploy through Git

## Status

Accepted

## Context

This project demonstrates contributors developing in a source repository and
delivering changes to a centralized PSU server through Git. Development and server
runtime are separate roles, even when they share a physical host.

This is an intentional deployment model for the reference implementation.
Downstream installations may begin with existing resources or adopt Git through
other migration paths.

## Decision

Develop and review resource changes in the source repository. Treat PSU's managed
Repository as read-only for contributors and agents, including through API, UI,
script, or other indirect operations that would modify its contents. Read-only
inspection may confirm that expected changes arrived.

Deliver resource changes through the agreed Git synchronization workflow:
contribution branch, pull request targeting `main`, authorized squash merge, then
PSU's automatic pull-only synchronization. Do not assume synchronization is
configured or that permission to edit source authorizes server configuration.

Keep development tooling and credentials separate from the server runtime.
Development tools and the contributor's local credential store must not become
runtime dependencies. Provision credentials required by runtime resources
separately on the server.

## Consequences

Git review and history provide a consistent delivery path. Direct resource edits
in PSU are outside this project's workflow, and merged changes take effect only
after synchronization. Setup and migration require deliberate steps; document
those procedures and observed obstacles in setup documentation rather than
expanding this decision into a deployment guide.
