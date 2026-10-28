Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ParDeviceAssignmentSnapshot {
    <#
    .SYNOPSIS
    Retrieves and composes one complete synthetic device-assignment investigation set.
    .DESCRIPTION
    App-specific composition for PAR IT Internal, callable outside PSU. Imports
    ParData and ParReports by repository-relative paths, retaining any existing
    ParData configuration without forcing a reimport. Reads Intune devices, CMDB
    assets, Entra users, and explicit person mappings once each. It does not select
    application fixture paths; configure ParData before calling this command.

    Buffers all required sources and all composition before emitting one snapshot.
    Terminating and nonterminating errors fail the call, even if a caller requests
    silent errors or a source emits records before failing. No partial snapshot
    is returned and no prior snapshot is stored or modified. Successfully empty
    inputs are valid; missing CMDB or identity evidence follows existing rules.

    Uses Compare-ParDeviceAssignedUser unchanged. Independently looks up Intune's
    UserId against Entra Id using trimmed, literal case-insensitive equality.
    Blank IDs never match. Zero, one, or multiple candidates produce Missing,
    Unique, or Ambiguous evidence; duplicate IDs are not deduplicated. Missing
    enrichment does not change comparison outcomes. Recorded user display fields
    remain source context, not identity keys.

    Resolves each correlated CMDB candidate independently with
    Resolve-ParCmdbAssignedUser, including every asset in ambiguous correlation.
    Existing resolver behavior applies: ambiguous person mappings retain their
    mapping candidates and do not select a UPN or query Entra for a chosen mapping.

    Uses ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport over these same devices,
    rather than retrieving them again. Each report entry references its existing
    investigation. Records remain in source order, including repeated IDs or
    serials. RecordNumber is a one-based position within this snapshot only;
    combine it with the retained snapshot when selecting a duplicate record.
    No live requests, source mutation, UI, or remediation occurs.
    .INPUTS
    None

    Pipeline input is not accepted.
    .OUTPUTS
    System.Management.Automation.PSCustomObject

    Inputs: IntuneDevice, CmdbAsset, EntraUser, and PersonMapping arrays containing
    the complete retrieved source objects.
    DeviceAssignments: array of investigation objects with RecordNumber,
    IntuneDeviceId, IntuneDevice, Outcome, Reason, Comparison (the unchanged full
    comparison result), IntunePrimaryUser, and CmdbAssignedUsers.
    IntunePrimaryUser: Outcome, Reason (BlankUserId, NoMatchingEntraUser,
    OneMatchingEntraUser, or MultipleMatchingEntraUsers), ComparisonUserId,
    EntraCandidateCount, and EntraCandidates array retaining original users.
    CmdbAssignedUsers: array of complete assigned-user resolver results, one per
    correlated CMDB candidate, retaining assets, mappings, Entra candidates, and
    missing or ambiguous reasons.
    WithoutPrimaryUser: array with RecordNumber, IntuneDeviceId, Report (the
    existing report row), and Investigation (the same object in DeviceAssignments).

    A successful call always returns one snapshot, including for zero devices.
    Collection properties are always arrays. Sources are references, not defensive
    copies; consumers must treat the snapshot and its evidence as read-only.
    .EXAMPLE
    Import-Module ./dashboards/ParITInternal/ParITInternal.psm1
    $snapshot = Get-ParDeviceAssignmentSnapshot
    $snapshot.DeviceAssignments | Select-Object IntuneDeviceId, Outcome, Reason
    .EXAMPLE
    $snapshot.WithoutPrimaryUser[0].Investigation

    Opens already composed evidence without rereading any source.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $ErrorActionPreference = 'Stop'
    Import-Module (Join-Path $PSScriptRoot '../../modules/ParData/ParData.psd1') -ErrorAction Stop
    Import-Module (Join-Path $PSScriptRoot '../../modules/ParReports/ParReports.psd1') -ErrorAction Stop

    $devices = @(Get-ParIntuneDevice -ErrorAction Stop)
    $assets = @(Get-ParCmdbAsset -ErrorAction Stop)
    $users = @(Get-ParEntraUser -ErrorAction Stop)
    $mappings = @(Get-ParCmdbPersonMapping -ErrorAction Stop)
    $comparisons = @(Compare-ParDeviceAssignedUser -InputObject $devices -CmdbAsset $assets -PersonMapping $mappings -EntraUser $users -ErrorAction Stop)
    $missingPrimaryUser = @()
    $investigations = @(
        for ($index = 0; $index -lt $comparisons.Count; $index++) {
            $comparison = $comparisons[$index]
            $device = $comparison.IntuneDevice
            $userId = ([string] $device.UserId).Trim()
            $candidates = @(
                if ($userId -ne '') {
                    foreach ($user in $users) {
                        $candidateId = ([string] $user.Id).Trim()
                        if ($candidateId -ne '' -and $candidateId -ieq $userId) {
                            $user
                        }
                    }
                }
            )
            $outcome = 'Missing'
            $reason = 'NoMatchingEntraUser'
            if ($userId -eq '') {
                $reason = 'BlankUserId'
            }
            elseif ($candidates.Count -eq 1) {
                $outcome = 'Unique'
                $reason = 'OneMatchingEntraUser'
            }
            elseif ($candidates.Count -gt 1) {
                $outcome = 'Ambiguous'
                $reason = 'MultipleMatchingEntraUsers'
            }

            $assignedUsers = @(Resolve-ParCmdbAssignedUser -InputObject $comparison.Correlation.CmdbCandidates -PersonMapping $mappings -EntraUser $users -ErrorAction Stop)
            $investigation = [pscustomobject][ordered]@{
                RecordNumber = $index + 1
                IntuneDeviceId = $device.Id
                IntuneDevice = $device
                Outcome = $comparison.Outcome
                Reason = $comparison.Reason
                Comparison = $comparison
                IntunePrimaryUser = [pscustomobject][ordered]@{
                    Outcome = $outcome
                    Reason = $reason
                    ComparisonUserId = $userId
                    EntraCandidateCount = $candidates.Count
                    EntraCandidates = $candidates
                }
                CmdbAssignedUsers = $assignedUsers
            }
            foreach ($row in (ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport -InputObject $device -ErrorAction Stop)) {
                $missingPrimaryUser += [pscustomobject][ordered]@{
                    RecordNumber = $index + 1
                    IntuneDeviceId = $device.Id
                    Report = $row
                    Investigation = $investigation
                }
            }
            $investigation
        }
    )

    [pscustomobject][ordered]@{
        Inputs = [pscustomobject][ordered]@{
            IntuneDevice = $devices
            CmdbAsset = $assets
            EntraUser = $users
            PersonMapping = $mappings
        }
        DeviceAssignments = $investigations
        WithoutPrimaryUser = $missingPrimaryUser
    }
}

Export-ModuleMember -Function Get-ParDeviceAssignmentSnapshot
