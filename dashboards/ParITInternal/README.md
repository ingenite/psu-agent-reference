# PAR IT Internal

The reports live at `/par-it-internal/reports`. This app shows administrators the
evidence behind device-assignment results instead of making them join exports by
hand. The rules belong to `ParReports` (`Get-Help Compare-ParDeviceAssignedUser
-Full`); this app composes and displays them.

## Constraints and why

- **Each result starts from an Intune record.** Intune records are never merged by
  serial number, and CMDB-only reconciliation is deferred. Every row then maps to
  one device an administrator can act on.
- **One snapshot per refresh.** `Get-PITIDeviceAssignmentSnapshot` retrieves every
  input once; investigations reuse it rather than reading sources again. Rows and
  details therefore can't disagree. This doesn't mean separate live sources were
  read atomically.
- **A failure is never shown as an empty result.** If a required source fails, the
  previous results are hidden until a retry succeeds, so a partial comparison
  can't look complete.
- **Ambiguity stays visible.** Multiple CMDB candidates or identity mappings are
  shown per candidate; the outcome remains `Unresolved`.
- **The companion module re-exports `ParITInternalCommands.psm1` under the `PITI`
  prefix.** Import the companion without adding another prefix.
- PSU must inject `PAR_FixturePaths` (or `*`) into the app's environment. Restart
  the app after changing modules or paths.
- The PSU server needs the Graph SDK modules listed in the root README. Without
  them, every refresh shows the source-failure alert. The app log warning
  `Device assignment refresh failed` names the missing module.

## Acceptance scenarios

- A mismatch shows both the Intune primary user and the CMDB assigned user, with
  their Entra records where available.
- A missing-primary-user row opens the same investigation, including for
  intentionally userless devices.
- Multiple CMDB candidates stay visible and unresolved, with evidence for each.
- Missing or ambiguous mappings explain why identity is incomplete; they are not
  labelled as an absent assignment.
- Empty results and a source failure look different.

`ParITInternal.Tests.ps1` covers these offline. PSU rendering was checked by hand;
see the errata for gaps.
