# ADR-0007: Place modules by responsibility

## Status

Accepted

## Context

Dashboards, automation scripts, and endpoints can share operations while retaining
their own presentation and orchestration. Repeating placement rules in feature
guides makes those rules drift as examples are added.

## Decision

- Put modules shared across PSU resources in top-level `modules/<ModuleName>/`,
  with a matching manifest and root module.
- Keep helpers used only by one dashboard in its companion `.psm1`, beside the
  dashboard `.ps1` with the same basename. PSU supports an
  [app-specific companion module](https://docs.devolutions.net/powershell-universal/apps/building-dashboards);
  verify the deployed app uses the intended files.
- A companion may load and explicitly re-export an adjacent dashboard-only
  implementation module when it must control command imports. PAR IT Internal
  uses this arrangement to import its implementation with `-Prefix PITI` while
  retaining PSU's companion-loading entry point. Both files remain dashboard
  resources; the implementation is not a platform module. Verify the exports in
  deferred execution contexts as well as at app startup.
- Keep presentation and resource orchestration in the resource. Shared modules
  own reusable operations and do not require a particular dashboard to run.
- Separate source-data retrieval from report transformations. `ParData` owns
  retrieval contracts and source-specific dependencies; `ParReports` owns shared
  queries and transformations over those objects.
- Make dependencies and loading requirements explicit. A source directory is
  not evidence of runtime discovery; verify the deployed PSU environment or
  import the required manifest by a portable path.

The directory guide owns the location reference. Feature guides explain the
specific modules they use rather than restating this placement policy.

## Consequences

Commands can be reused and tested outside a dashboard. Dashboard-only helpers
remain local, and shared modules are introduced for actual responsibilities
rather than speculative reuse. Deployment still requires verification of module
availability and dependencies.
