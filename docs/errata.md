# Errata and verification limits

This is the authoritative record of known limitations and verification gaps.
Update the relevant entry when evidence changes. A passing isolated test does not
establish live PSU or external-service behavior.

## Microsoft services and Intune data

There is no Microsoft tenant for this project. Resources have not been verified
against live Microsoft Graph endpoints. The Intune examples use synthetic data;
the factory and retrieval implementation construct actual SDK models offline.

Compatibility with SDK versions other than the documented requirement is not
established. Offline tests and model probes exercise construction, export,
retrieval, and reporting; they do not
establish tenant permissions, enrollment behavior, or live primary-user semantics.

The report uses a missing `UserId` as its demonstration selection rule. It does
not inspect Graph's primary-user relationship. No verified mapping from Autopilot
deployment modes to the synthetic enrollment types is provided.

## CMDB assets

The CMDB asset schema is a small demonstration projection grounded in public
Atlassian Assets documentation, not a vendor API representation. Verification
uses local PowerShell objects and synthetic CSV fixtures only. No live CMDB
provider or API compatibility has been verified. CMDB retrieval through ParData,
device correlation, person-reference resolution to Entra users, and assignment
comparison are not implemented. Intentional fixture relationships do not establish
a correlation rule or a user mapping.

## PSU execution

Offline shared-variable tests set a global PowerShell variable in the test
process. They do not verify PSU environment injection, module discovery, or
execution of the Intune example in a PSU resource. A dashboard and HTTP endpoints
for the report have not yet been shipped.

## Management API tools and Git

The Git settings and SSH-key wrappers were checked against PSU 2026.3.0's
Management API schema. Their sibling tests mock HTTP calls. Live read access was
checked separately during development; this does not establish live save,
create, rename, or delete behavior for the wrappers.

The mapping from the Git settings API's `gitSshKey` string to an SSH-key response
has not been verified. SSH key selection and unattended Git access under the PSU
service account remain deployment-specific verification work. The guides target
GitHub; other Git hosts have not been verified.

Saving settings does not prove that a configuration is assigned, active, or able
to reach a Git remote. Confirm effective configuration and a fresh relevant
operation when verifying a deployment.
