# Errata and verification limits

This is the authoritative record of known limitations and verification gaps.
Update the relevant entry when evidence changes.

Unless a live check is explicitly identified, verification uses synthetic data,
isolated tests, and offline probes. These checks do not establish live PSU or
external-service behavior, permissions, or compatibility beyond the documented
dependency versions. Using actual SDK models or vendor documentation does not
extend that verification scope.

## Interpretation limits

The primary-user report uses a missing `UserId` as its demonstration selection
rule. Primary User is the intended terminology for the single-user Windows
scenario; this limitation does not require a different report label. The current
implementation does not separately query Graph's primary-user relationship.
No verified mapping from Autopilot deployment modes to the synthetic enrollment
types is provided.

The CMDB schema and person-to-UPN mappings are demonstration choices, not a vendor
API contract or verified identity directory. CMDB person references are distinct
from Entra IDs. Unique matches in supplied datasets do not independently verify
identity or the accuracy, freshness, and completeness of live sources.

Serial numbers can occur on multiple Intune device records, although uncommon; a serial-number match identifies a candidate CMDB asset, not a unique Intune record.

## PSU execution

PSU 2026.3.0 development-instance checks exercised synthetic module loading,
JSON fixture-path injection, both reports, shared investigation modals, candidate
evidence, refresh, loading, empty results, failure/retry, and light/dark layouts.
Pages declare `-AutoInclude`; reloading `dashboards.ps1` through the management
API activated the updated declarations. The simplified bootstrap and default
theme were checked through the Reports home page, both report routes,
Reports-only navigation, and light/dark report and investigation-modal rendering.
In the owner's new-page test, an app restart did not make the copied page
available; forcing the pending file-change Reload did. Automatic discovery timing
remains unverified. Module changes were checked after an app restart.
Page-owned report composition and argument-free refresh were rechecked in both
reports, including stale-selection rejection, retained search/filter controls on
modal close, candidate evidence, and empty/failure/retry states.
The PITI command refactor was checked after a development-app restart: the
companion imported and re-exported the adjacent implementation module, both
reports rendered table summaries and refreshed their dynamic content, and
investigation callbacks rendered assignments and expandable Intune/CMDB evidence.
Object-valued variable injection was unreliable here, so fixture paths use JSON.
The synchronized instance and live Graph, CMDB, tenant data, and permissions
remain unverified.

## Management API tools and Git

The Git settings and SSH-key wrappers were checked against PSU 2026.3.0's
Management API schema. Unlike the offline checks above, live read access was
checked separately during development. Their sibling tests mock HTTP calls;
live save, create, rename, and delete behavior remains unverified.

The mapping from the Git settings API's `gitSshKey` string to an SSH-key response
has not been verified. SSH key selection and unattended Git access under the PSU
service account remain deployment-specific verification work. The guides target
GitHub; other Git hosts have not been verified.

Saving settings does not prove that a configuration is assigned, active, or able
to reach a Git remote. Confirm effective configuration and a fresh relevant
operation when verifying a deployment.
