# Device assignment investigation

## Status and purpose

Both reports are available from Reports in PAR IT Internal. Investigate opens a
shared modal with the result and assignments first, followed by expandable source
evidence. Closing it preserves the report controls.
PAR IT Internal is a collection of pages and reports that brings related platform
information together so administrators can investigate without manually joining
exports or navigating separate systems. The first workflow concerns device
assignments; later scenarios can evolve incrementally from this foundation.

ParData retrieval and ParReports correlation, identity resolution, comparison,
and the missing-primary-user report are implemented. They are supporting pieces
of this experience, not a requirement for separate pages for every function.

## Administrator journey

1. Open Device assignments and filter results by comparison outcome.
2. Select an Intune device record to open its investigation view.
3. Inspect the Intune record, candidate CMDB assets, available Entra records on
   both assignment sides, and the evidence explaining the result.
4. Reach the same investigation view from the Windows devices without a primary
   user report. Keep the selected Intune record identity across navigation.

Use **Primary User** terminology for the single-user Windows device scenario.
Show Intune's UserDisplayName, UserPrincipalName, and UserId as recorded source
values, and use UserId to find Entra users by Id. Display fields provide context;
they do not replace ID comparison. Shared and kiosk devices may intentionally
have no primary user, so a missing value is not inherently a defect.

The initial workflow is Intune-led: each Intune record has a result. CMDB-only
asset reconciliation is deferred. Do not merge Intune records by serial number.

## Report and investigation content

The assignment list identifies the device by name and serial, shows primary-user
and CMDB assignment context, and displays the outcome. The investigation explains
the reason and retains identifiers and candidate evidence rather than flattening
ambiguity into a chosen account.

The shared investigation view should expose:

- Intune identifiers, hardware and OS context, sync/enrollment timestamps, and
  recorded primary-user fields.
- Every correlated CMDB asset, its identifiers, serial, and assigned-person
  reference, including the correlation reason and candidate count.
- Entra candidates found independently from Intune UserId, with missing or
  ambiguous evidence made explicit.
- CMDB person-mapping evidence and Entra candidates for the assigned person.
  For ambiguous assets, explain each candidate separately without choosing one
  or changing the unresolved comparison outcome.
- Relevant Entra IDs, display names, UPNs, mail, and account state. Account state
  is context, not an alternative identity key or automatic remediation signal.

Retain the existing Match, Mismatch, MissingAssignment, and Unresolved rules.
Missing investigation enrichment must not silently redefine those rules.

## Composition and retrieval

Retain ParData's SDK-backed Intune and Entra objects and the small CMDB
projection. Compatible future retrieval must also satisfy the properties,
dataset completeness, and failure behavior consumers require. Live providers
and a generic provider framework are outside this initial delivery.

Retrieve a complete set of required inputs for a refresh, then use that set for
its report results and investigation details. Do not independently reread sources
when opening details for an existing result. A complete retrieval set is not a
claim that separate live platforms were read atomically.

Person mappings are an explicit required input alongside Intune, CMDB, and Entra.
ParData owns their retrieval through `Get-ParCmdbPersonMapping` and the
`PersonMapping` fixture configuration key. Report transformations continue
receiving objects without CSV paths.

Place initial app-specific snapshot composition in the dashboard companion module.
Keep reusable source operations in ParData and transformations in ParReports;
extract additional shared orchestration when another consumer needs it.

Each report page declares its layout, session loading and refresh, investigation
selection, table columns, and investigation action. The companion module prepares
shared display rows and renders the shared investigation modal from explicitly
supplied state.

Import `dashboards/ParITInternal/ParITInternal.psm1` to use
`Get-PITIDeviceAssignmentSnapshot` for the offline composition shared by both
reports and their investigation details. The companion imports the adjacent
`ParITInternalCommands.psm1` with `-Prefix PITI` and explicitly re-exports its ten
commands. Do not add another prefix when importing the companion. The command's
usage and result contract are available through
`Get-Help Get-PITIDeviceAssignmentSnapshot -Full` after importing the companion.

Show loading, successful empty results, and retrieval failure distinctly. If a
required source fails, do not publish a newly computed, apparently complete
comparison. A successfully retrieved empty source is different from a failure.
Keep **Demo · Synthetic data** visible throughout the application.

Use the shared demonstration files directly in `data/` across reports and the
application. Extend shared synthetic data only to meet an identified report or
investigation need.

## Setup and refresh

Use the registered PowerShell 7 app with its companion and implementation modules,
page files, ParData, ParReports, and the four shared CSVs in `data/`. The environment must
inject `PAR_FixturePaths` (or `*`); fixture retrieval and generation guides own
configuration and regeneration. Restart the app after module or path changes.

Open `/par-it-internal/reports`. Both reports and their investigation modals reuse
one session snapshot. **Refresh data** replaces it for both reports; failure hides
previous results until a successful retry. Empty retrieval shows **No results**.

## Acceptance scenarios

- A mismatch opens evidence identifying both the Intune primary user and the
  CMDB assigned user, including their Entra records where available.
- A missing-primary-user row opens the same investigation view and preserves
  its Intune identity, including intentionally userless examples.
- Multiple CMDB candidates remain visible and unresolved, with per-candidate
  identity evidence; no duplicate is silently selected.
- Missing or ambiguous person mappings and Entra candidates explain why identity
  evidence is incomplete without being mislabeled as an absent assignment.
- Report rows and details use the same retrieved input set until refresh.
- Empty results and a required-source failure produce different visible states;
  a failed refresh does not publish partial new results.
- Offline composition tests exercise the existing SDK fixtures through ParData
  and ParReports. PSU verification separately covers module discovery, shared
  variables, navigation, loading, empty, and failure behavior.
