# Errata and verification limits

This is the authoritative record of known limitations and verification gaps.
Update the relevant entry when evidence changes.

Unless a live check is explicitly identified, verification uses synthetic data,
isolated tests, and offline probes. These checks do not establish live PSU or
external-service behavior, permissions, or compatibility beyond the documented
dependency versions. Using actual SDK models or vendor documentation does not
extend that verification scope.

## Interpretation limits

The report uses a missing `UserId` as its demonstration selection rule. It does
not inspect Graph's primary-user relationship. No verified mapping from Autopilot
deployment modes to the synthetic enrollment types is provided.

The CMDB schema is a demonstration projection, not a vendor API representation.
Intentional fixture relationships do not establish device correlation or user
identity mapping. Matching display names, UPNs, or mail values do not establish
identity equality; CMDB person references are not assumed to be Entra IDs.

Serial numbers can occur on multiple Intune device records, although uncommon; a serial-number match identifies a candidate CMDB asset, not a unique Intune record.

## PSU execution

Offline shared-variable tests set a global PowerShell variable in the test
process, bypassing PSU environment injection and module discovery. Execution of
the report in a PSU resource remains unverified.

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
