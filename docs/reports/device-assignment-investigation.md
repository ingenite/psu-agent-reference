# Device assignment investigation

## Status and purpose

Agreed direction for Issue #20; the assembled experience is not implemented yet.
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

The assignment list should identify the device by name and Intune ID, show its
serial number, primary-user context, CMDB assignment context where available,
and comparison outcome and reason. Keep detailed candidate evidence in the
investigation view rather than flattening ambiguity into a chosen account.

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
Give their retrieval and configuration an explicit owner during the next slice;
report transformations must continue receiving objects without CSV paths.

Place initial app-specific orchestration in the dashboard companion module.
Keep reusable source operations in ParData and transformations in ParReports;
extract additional shared orchestration when another consumer needs it.

Show loading, successful empty results, and retrieval failure distinctly. If a
required source fails, do not publish a newly computed, apparently complete
comparison. A successfully retrieved empty source is different from a failure.
Keep **Demo · Synthetic data** visible throughout the application.

Use one coherent application demonstration dataset. Retain focused unit-test
fixtures and the existing comparison scenarios; extend synthetic data or its
machinery only to meet an identified report or investigation requirement.

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

## Next slice and open choices

Next, implement and test the bounded data composition needed by the shared
investigation view: complete input retrieval, unchanged comparison results,
Intune-side Entra enrichment, and per-candidate CMDB identity evidence. Then
connect the two report entry points to that view and verify the assembled app.

Before implementing that slice, settle the person-mapping retrieval/configuration
owner and the app-facing result contract. Choose the application dataset from
the existing fixtures or a proportionate adaptation. Exact page layout, refresh
controls, and whether a failed refresh retains clearly labeled previous results
remain implementation choices to review. No live integration, remediation, or
additional scenario is authorized by this plan.
