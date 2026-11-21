# Device assignment reports

## The problem

Admins often have to answer "who actually has this laptop?" The answer is spread
across three systems that don't agree. Intune records a primary user, the CMDB
records an assigned person, and Entra holds the accounts. Joining CSV exports by
hand is slow and easy to get wrong.

**PAR IT Internal** (`/par-it-internal/reports` in PSU) does the join and shows the
evidence behind each result, so you can see *why* a device looks wrong, not just
that it does.

## The two reports

- **Device assignments**: each Intune device's primary user compared with the
  CMDB's assigned person.
- **Windows devices without a primary user**: Intune records with no user.

Both open the same **Investigate** view, which shows the Intune record, every
matching CMDB asset, how the CMDB person was mapped to an account, and the Entra
accounts on both sides.

## Design decisions

- **Every result has one of four outcomes:** `Match`, `Mismatch`,
  `MissingAssignment` or `Unresolved`. "Unresolved" exists so the tool never
  guesses. If two CMDB assets share a serial number, or a person maps to two
  accounts, you see both candidates rather than a silent pick.
- **IDs are compared, not names.** Display names and email addresses are shown
  for context, but only the Entra user ID decides a match. Names collide and
  change.
- **A missing user isn't automatically a problem.** Shared and kiosk devices
  normally have no primary user. The report describes what the records say and
  leaves the judgment to you.
- **One snapshot per refresh.** Reports and investigations use the same data
  until you click **Refresh data**. If a source fails, the old results disappear
  rather than showing a half-updated picture.
- **The work is split into layers.** `ParData` reads sources, `ParReports` applies
  the rules, and the dashboard only displays results. That lets a script, an API
  endpoint or a different app reuse the same rules.

## Try it

Ask your agent to run the comparison locally. The repository's shared data in
`data/` includes eleven scenarios (serials `COMPARE-001` to `COMPARE-011`), one
for each outcome and edge case. The rules themselves are documented in
`Get-Help Compare-ParDeviceAssignedUser -Full`.

The data is entirely synthetic. Live Graph and CMDB connections have not been
built or verified; see the errata.
