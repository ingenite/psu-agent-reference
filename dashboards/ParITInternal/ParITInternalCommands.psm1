Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-DeviceAssignmentSnapshot {
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
    $snapshot = Get-PITIDeviceAssignmentSnapshot
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

    $devices = @(ParData\Get-ParIntuneDevice -ErrorAction Stop)
    $assets = @(ParData\Get-ParCmdbAsset -ErrorAction Stop)
    $users = @(ParData\Get-ParEntraUser -ErrorAction Stop)
    $mappings = @(ParData\Get-ParCmdbPersonMapping -ErrorAction Stop)
    $comparisons = @(ParReports\Compare-ParDeviceAssignedUser -InputObject $devices -CmdbAsset $assets -PersonMapping $mappings -EntraUser $users -ErrorAction Stop)
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

            $assignedUsers = @(ParReports\Resolve-ParCmdbAssignedUser -InputObject $comparison.Correlation.CmdbCandidates -PersonMapping $mappings -EntraUser $users -ErrorAction Stop)
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
            foreach ($row in (ParReports\ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport -InputObject $device -ErrorAction Stop)) {
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

function New-DeviceAssignmentState {
    <#
    .SYNOPSIS
    Loads a complete report state or a failure state with no retained results.
    .DESCRIPTION
    Calls Get-DeviceAssignmentSnapshot once. Success receives a new opaque
    snapshot ID and load timestamp, including for empty inputs. Failure emits a
    warning for the app log and returns Failed with no snapshot, ID, or timestamp.
    The caller replaces its session state with this object; previous results are
    never included. Does not render UI or mutate any source.
    .OUTPUTS
    System.Management.Automation.PSCustomObject
    .EXAMPLE
    $state = New-PITIDeviceAssignmentState
    #>
    [CmdletBinding()]
    param()

    try {
        $snapshot = Get-DeviceAssignmentSnapshot -ErrorAction Stop
        [pscustomobject]@{
            Status = 'Ready'
            Snapshot = $snapshot
            SnapshotId = [string] (New-Guid)
            LoadedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'
        }
    }
    catch {
        Write-Warning "Device assignment refresh failed: $($_.Exception.Message)"
        [pscustomobject]@{
            Status = 'Failed'
            Snapshot = $null
            SnapshotId = $null
            LoadedAt = $null
        }
    }
}

function Get-DeviceInvestigation {
    <#
    .SYNOPSIS
    Selects an existing investigation using its snapshot ID and record position.
    .DESCRIPTION
    Returns no result for missing, failed, expired, malformed, or out-of-range
    selections. Never retrieves sources. Record positions distinguish duplicate
    Intune IDs and serials within the retained snapshot. Selections are session-bound;
    a new refresh or browser session invalidates old selections.
    .PARAMETER State
    State returned by New-PITIDeviceAssignmentState, or null before loading.
    .PARAMETER SnapshotId
    Opaque ID carried by the report row.
    .PARAMETER RecordNumber
    One-based record position carried as text by the report row.
    .OUTPUTS
    System.Management.Automation.PSCustomObject
    .EXAMPLE
    Get-PITIDeviceInvestigation -State $state -SnapshotId $state.SnapshotId -RecordNumber '2'
    #>
    [CmdletBinding()]
    param(
        [AllowNull()] $State,
        [string] $SnapshotId,
        [string] $RecordNumber
    )

    if ($null -eq $State -or $State.Status -ne 'Ready' -or $SnapshotId -cne $State.SnapshotId) { return }
    if ($RecordNumber -notmatch '^[1-9][0-9]{0,8}$') { return }
    $position = [int] $RecordNumber
    $snapshot = $State.Snapshot
    $investigations = $snapshot.DeviceAssignments
    if ($position -gt $investigations.Count) { return }
    $investigations[$position - 1]
}

function Get-AssignmentReasonText {
    param([string] $Reason)

    $reasons = @{
        SameUserId = 'Both assignments resolve to the same Entra user ID.'
        DifferentUserIds = 'The Intune and CMDB assignments identify different Entra users.'
        IntuneAssignmentMissing = 'Intune has no recorded primary user; CMDB has a resolved assignment.'
        CmdbAssignmentMissing = 'CMDB has no assigned person; Intune has a recorded primary user.'
        BothAssignmentsMissing = 'Neither source records an assignment. Shared or kiosk devices may intentionally have no primary user.'
        CmdbAssetMissing = 'No CMDB asset could be correlated with this Intune record.'
        CmdbAssetAmbiguous = 'Multiple CMDB assets match; no asset is selected.'
        CmdbAssignedUserUnresolved = 'The CMDB assigned person could not be resolved uniquely.'
        BlankSerialNumber = 'The Intune serial number is blank.'
        NoMatchingSerialNumber = 'No CMDB asset has a matching serial number.'
        OneMatchingCmdbRecord = 'One CMDB asset has a matching serial number.'
        MultipleMatchingCmdbRecords = 'Multiple CMDB assets have a matching serial number.'
        BlankUserId = 'Intune has no recorded primary-user ID.'
        NoMatchingEntraUser = 'No Entra user matches the supplied identity key.'
        OneMatchingEntraUser = 'One Entra user matches the recorded Intune UserId.'
        MultipleMatchingEntraUsers = 'Multiple Entra users match. No identity candidate is selected.'
        BlankAssignedUserReference = 'The CMDB asset has no assigned-person reference.'
        NoPersonMapping = 'No person mapping exists for the CMDB assigned-person reference.'
        MultiplePersonMappings = 'Multiple person mappings exist. No mapping is selected and no Entra lookup is made.'
        BlankMappedUserPrincipalName = 'The person mapping has no UPN for an Entra lookup.'
        BlankEntraObjectId = 'The matching Entra record has no object ID.'
        OneMappedEntraUser = 'One person mapping and one Entra user resolve this assigned-person reference.'
    }
    if ($reasons.ContainsKey($Reason)) { $reasons[$Reason] } else { $Reason }
}

function Get-AssignmentOutcomeText {
    param([string] $Outcome)

    if ($Outcome -eq 'MissingAssignment') { 'Missing assignment' } else { $Outcome }
}

function New-EvidenceTable {
    param($Record, $Fields)

    $rows = @(
        foreach ($field in $Fields.GetEnumerator()) {
            $value = $Record.($field.Key)
            $text = [string] $value
            if ($value -is [datetime]) { $text = Get-Date -Date $value -Format o }
            if ($text.Trim() -eq '') { $text = 'Not recorded' }
            [pscustomobject]@{ Field = $field.Value; Value = $text }
        }
    )
    New-UDTable -Id (New-Guid) -Data $rows -Dense -RemoveCard -Columns @(
        New-UDTableColumn -Property Field -Title 'Field'
        New-UDTableColumn -Property Value -Title 'Value'
    )
}

function New-EntraEvidence {
    param([AllowEmptyCollection()] [object[]] $Users)

    if ($Users.Count -eq 0) {
        New-UDTypography -Text 'No Entra candidates.'
    }
    foreach ($user in $Users) {
        New-EvidenceTable -Record $user -Fields ([ordered]@{
            DisplayName = 'Name'
            UserPrincipalName = 'UPN'
            Id = 'Entra user ID'
            Mail = 'Mail'
            AccountEnabled = 'Account enabled'
        })
    }
}

function New-AssignmentSummary {
    param([string] $Name, [string] $Upn, [string] $Fallback)

    New-UDStack -Id (New-Guid) -Direction column -Spacing 1 -Children {
        if ($Name.Trim() -ne '') { New-UDTypography -Text $Name -Variant subtitle2 }
        if ($Upn.Trim() -ne '') { New-UDTypography -Text $Upn -Variant body2 }
        if ($Name.Trim() -eq '' -and $Upn.Trim() -eq '') {
            New-UDTypography -Text $Fallback -Variant body2
        }
    }
}

function ConvertTo-DeviceAssignmentRow {
    <#
    .SYNOPSIS
    Prepares shared display rows from already selected investigations.
    .DESCRIPTION
    Preserves source order and record positions. Formats assignment summaries and
    labels without retrieving sources, selecting a report, accessing session state,
    or rendering PSU components. The caller supplies the retained snapshot ID.
    .PARAMETER Investigation
    Investigations selected from one device-assignment snapshot.
    .PARAMETER SnapshotId
    Identity of the state containing the supplied investigations.
    .OUTPUTS
    System.Management.Automation.PSCustomObject
    .EXAMPLE
    ConvertTo-PITIDeviceAssignmentRow -Investigation $state.Snapshot.DeviceAssignments -SnapshotId $state.SnapshotId
    #>
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()] [object[]] $Investigation,
        [string] $SnapshotId
    )

    foreach ($deviceInvestigation in $Investigation) {
        $device = $deviceInvestigation.IntuneDevice
        $assignedUsers = $deviceInvestigation.CmdbAssignedUsers
        $cmdbName = ''
        $cmdbUpn = ''
        $cmdbSummary = 'No matching asset'
        if ($assignedUsers.Count -gt 1) {
            $cmdbSummary = "$($assignedUsers.Count) asset candidates"
        }
        elseif ($assignedUsers.Count -eq 1) {
            $resolution = $assignedUsers[0]
            $cmdbSummary = 'Unresolved person'
            if (([string] $resolution.AssignedUserReference).Trim() -eq '') { $cmdbSummary = 'Not assigned' }
            if ($resolution.EntraCandidateCount -eq 1) {
                $user = $resolution.EntraCandidates[0]
                $cmdbName = $user.DisplayName
                $cmdbUpn = $user.UserPrincipalName
            }
        }
        [pscustomobject]@{
            RecordNumber = $deviceInvestigation.RecordNumber
            SnapshotId = $SnapshotId
            DeviceName = $device.DeviceName
            IntuneDeviceId = $deviceInvestigation.IntuneDeviceId
            SerialNumber = $device.SerialNumber
            PrimaryUser = $device.UserPrincipalName
            PrimaryUserName = $device.UserDisplayName
            PrimaryUserId = $device.UserId
            CmdbAssignment = (@($assignedUsers | ForEach-Object { $_.AssignedUserReference }) -join ', ')
            CmdbUserName = $cmdbName
            CmdbUserUpn = $cmdbUpn
            CmdbSummary = $cmdbSummary
            Outcome = Get-AssignmentOutcomeText $deviceInvestigation.Outcome
            Reason = Get-AssignmentReasonText $deviceInvestigation.Reason
        }
    }
}

function Show-DeviceInvestigationDialog {
    <#
    .SYNOPSIS
    Opens shared evidence for a record in the supplied report state.
    .DESCRIPTION
    Validates the snapshot identity and record position before rendering. Stale or
    invalid selections show an unavailable message. Does not retrieve sources or
    access session state; the page supplies its current state when clicked.
    .PARAMETER State
    Current state returned by New-PITIDeviceAssignmentState, or null before loading.
    .PARAMETER SnapshotId
    Snapshot identity carried by the selected report row.
    .PARAMETER RecordNumber
    Record position carried by the selected report row.
    #>
    param(
        [AllowNull()] $State,
        [string] $SnapshotId,
        [string] $RecordNumber
    )

    $investigation = Get-DeviceInvestigation -State $State -SnapshotId $SnapshotId -RecordNumber $RecordNumber
    if ($null -eq $investigation) {
        Show-UDModal -Content {
            New-UDAlert -Severity warning -Title 'Investigation unavailable' -Text 'The loaded data has changed. Refresh the report and select the device again.'
        } -Footer { New-UDButton -Text 'Close' -OnClick { Hide-UDModal } }
        return
    }
    $device = $investigation.IntuneDevice
    $intuneUser = $investigation.IntunePrimaryUser
    $correlation = $investigation.Comparison.Correlation
    $assignedUsers = $investigation.CmdbAssignedUsers
    $loadedAt = $State.LoadedAt
    Show-UDModal -FullWidth -MaxWidth 'md' -Dividers -Header {
        New-UDTypography -Text $device.DeviceName -Variant h6
    } -Content {
        New-UDStack -Direction column -Spacing 2 -Children {
            New-UDAlert -Severity info -Title (Get-PITIAssignmentOutcomeText $investigation.Outcome) -Text (Get-PITIAssignmentReasonText $investigation.Reason)
            New-UDGrid -Container -Spacing 2 -Children {
                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                    New-UDStack -Direction column -Spacing 1 -Children {
                        New-UDTypography -Text 'Intune primary user' -Variant body2
                        New-PITIAssignmentSummary -Name $device.UserDisplayName -Upn $device.UserPrincipalName -Fallback 'Not recorded'
                    }
                }
                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                    New-UDStack -Direction column -Spacing 1 -Children {
                        New-UDTypography -Text 'CMDB assigned user' -Variant body2
                        if ($assignedUsers.Count -eq 0) {
                            New-UDTypography -Text 'No matching asset' -Variant body2
                        }
                        foreach ($resolution in $assignedUsers) {
                            if ($assignedUsers.Count -gt 1) {
                                New-UDTypography -Text "Candidate $($resolution.CmdbAssetId)" -Variant subtitle2
                            }
                            if ($resolution.EntraCandidateCount -eq 1) {
                                $user = $resolution.EntraCandidates[0]
                                New-PITIAssignmentSummary -Name $user.DisplayName -Upn $user.UserPrincipalName
                            }
                            else {
                                New-UDTypography -Text (Get-PITIAssignmentReasonText $resolution.Reason) -Variant body2
                            }
                        }
                    }
                }
            }
            New-UDTypography -Text "Serial: $($device.SerialNumber) · Updated $loadedAt" -Variant caption
            New-UDExpansionPanelGroup -Children {
                New-UDExpansionPanel -Title 'Device details' -Children {
                    New-PITIEvidenceTable -Record $device -Fields ([ordered]@{
                        DeviceName = 'Device name'
                        Id = 'Intune device ID'
                        AzureAdDeviceId = 'Entra device ID'
                        SerialNumber = 'Serial number'
                        Manufacturer = 'Manufacturer'
                        Model = 'Model'
                        OperatingSystem = 'Operating system'
                        OSVersion = 'OS version'
                        DeviceEnrollmentType = 'Enrollment type'
                        EnrolledDateTime = 'Enrolled'
                        LastSyncDateTime = 'Last sync'
                    })
                }
                New-UDExpansionPanel -Title "Intune identity · candidates: $($intuneUser.EntraCandidateCount)" -Children {
                    New-UDStack -Direction column -Spacing 2 -Children {
                        New-UDTypography -Text (Get-PITIAssignmentReasonText $intuneUser.Reason) -Variant body2
                        New-PITIEvidenceTable -Record $device -Fields ([ordered]@{
                            UserDisplayName = 'Recorded name'
                            UserPrincipalName = 'Recorded UPN'
                            UserId = 'Recorded user ID'
                        })
                        New-PITIEntraEvidence -Users $intuneUser.EntraCandidates
                    }
                }
                New-UDExpansionPanel -Title "CMDB evidence · assets: $($correlation.CandidateCount)" -Children {
                    New-UDStack -Direction column -Spacing 2 -Children {
                        New-UDTypography -Text (Get-PITIAssignmentReasonText $correlation.Reason) -Variant body2
                        foreach ($resolution in $assignedUsers) {
                            New-UDTypography -Text "Asset $($resolution.CmdbAssetId)" -Variant subtitle1
                            New-PITIEvidenceTable -Record $resolution.CmdbAsset -Fields ([ordered]@{
                                assetId = 'Asset ID'
                                assetTag = 'Asset tag'
                                deviceName = 'Device name'
                                serialNumber = 'Serial number'
                                assignedUserReference = 'Assigned person'
                            })
                            New-UDTypography -Text (Get-PITIAssignmentReasonText $resolution.Reason) -Variant body2
                            New-UDTypography -Text "Person mappings ($($resolution.MappingCount))" -Variant subtitle2
                            if ($resolution.MappingCount -gt 0) {
                                New-UDTable -Data @($resolution.MappingCandidates) -Dense -RemoveCard -Columns @(
                                    New-UDTableColumn -Property personReference -Title 'Person reference'
                                    New-UDTableColumn -Property userPrincipalName -Title 'Mapped UPN'
                                )
                            }
                            New-UDTypography -Text "Entra candidates ($($resolution.EntraCandidateCount))" -Variant subtitle2
                            New-PITIEntraEvidence -Users $resolution.EntraCandidates
                        }
                    }
                }
            }
        }
    } -Footer {
        New-UDTypography -Text 'Demo · Synthetic data' -Variant caption
        New-UDButton -Text 'Close' -OnClick { Hide-UDModal }
    }
}

# The companion applies PITI and re-exports these commands for PSU callbacks.
Export-ModuleMember -Function @(
    'Get-DeviceAssignmentSnapshot'
    'New-DeviceAssignmentState'
    'Get-DeviceInvestigation'
    'ConvertTo-DeviceAssignmentRow'
    'Show-DeviceInvestigationDialog'
    'Get-AssignmentReasonText'
    'Get-AssignmentOutcomeText'
    'New-EvidenceTable'
    'New-EntraEvidence'
    'New-AssignmentSummary'
)
