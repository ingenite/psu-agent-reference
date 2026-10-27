function Compare-ParDeviceAssignedUser {
    <#
    .SYNOPSIS
    Compares Intune user IDs with uniquely resolved CMDB assigned-user IDs.
    .DESCRIPTION
    Transforms supplied source objects without retrieval, source mutation, or
    external requests. Reuses Resolve-ParIntuneDeviceCmdbAsset for serial-number
    correlation and Resolve-ParCmdbAssignedUser for explicit person-to-UPN-to-ID
    resolution. All devices are included; OS and descriptive user fields do not
    filter results or establish identity. No assignments are changed.

    Evaluates evidence in this order:
    1. Missing or ambiguous CMDB correlation produces Unresolved with reason
       CmdbAssetMissing or CmdbAssetAmbiguous, even if Intune UserId is blank.
    2. For one asset, a blank assignedUserReference is a missing CMDB assignment.
       A nonblank reference that cannot resolve uniquely produces Unresolved/
       CmdbAssignedUserUnresolved, even if Intune UserId is blank. The nested
       resolution retains the specific missing or ambiguous reason.
    3. With a known CMDB assignment state, a blank Intune UserId or blank CMDB
       reference produces MissingAssignment. Reasons are IntuneAssignmentMissing,
       CmdbAssignmentMissing, or BothAssignmentsMissing. Two blanks are not a match.
    4. Two nonblank IDs are compared after Trim(), using PowerShell's literal
       case-insensitive equality (-ieq). Equal IDs produce Match/SameUserId;
       different IDs produce Mismatch/DifferentUserIds. Internal whitespace,
       punctuation, and leading zeroes remain significant. IDs stay opaque;
       UPN, mail, names, and account state are not alternative comparison keys.

    Results describe supplied datasets under demonstration rules. They do not
    independently verify identity, query Graph's primary-user relationship,
    identify an assignment problem, or recommend remediation.
    .PARAMETER InputObject
    Intune source objects exposing Id, SerialNumber, and UserId, as returned by
    Get-ParIntuneDevice. Accepts arrays or pipeline input. Emits one result per
    non-null device in source order, preserving duplicates. Null input, empty
    arrays, and empty pipelines emit no results.
    .PARAMETER CmdbAsset
    Complete CMDB dataset exposing assetId, serialNumber, and assignedUserReference.
    Null elements are ignored; null or empty input has no CMDB candidates.
    Duplicate candidates remain ambiguous even if their assignments agree.
    .PARAMETER PersonMapping
    Complete explicit mapping dataset exposing personReference and userPrincipalName.
    Null elements are ignored. Null or empty input has no mappings; a nonblank
    CMDB person reference then remains unresolved rather than unassigned.
    .PARAMETER EntraUser
    Complete Entra dataset exposing Id and UserPrincipalName. Null elements are
    ignored; null or empty input has no users. Duplicate matches remain ambiguous.
    Equivalent plain source objects support isolated use without Graph. Non-null
    objects must follow these source contracts; missing properties terminate under
    module strict mode. No malformed source models are repaired.
    .INPUTS
    System.Object[]

    Intune source objects, individually or as an array.
    .OUTPUTS
    System.Management.Automation.PSCustomObject

    IntuneDeviceId, IntuneDevice: original Intune ID and source object.
    IntuneUserId: original UserId, preserving null, empty, and whitespace.
    CmdbEntraObjectId: original resolved Entra ID, or null if not resolved.
    ComparisonIntuneUserId: trimmed Intune ID; empty for a blank ID.
    ComparisonCmdbEntraObjectId: trimmed resolved ID; null unless resolved.
    Outcome, Reason: values described above.
    Correlation: the full device-to-CMDB resolver result with all candidates.
    AssignedUserResolution: the full person resolver result for a unique asset;
    null when correlation is missing or ambiguous. Nested results retain source
    records, candidates, reasons, and counts without silently choosing duplicates.

    Source objects are references, not copies. This command leaves them unchanged;
    consumers must not mutate them through results if retaining source evidence.
    .EXAMPLE
    Import-Module ./modules/ParData/ParData.psd1
    Import-Module ./modules/ParReports/ParReports.psd1
    $devices = @(Get-ParIntuneDevice)
    $parameters = @{
        CmdbAsset = @(Get-ParCmdbAsset)
        PersonMapping = @(Import-Csv -LiteralPath ./data/cmdb-person-mappings.csv)
        EntraUser = @(Get-ParEntraUser)
    }
    $results = @($devices | Compare-ParDeviceAssignedUser @parameters)
    $results | Select-Object IntuneDeviceId, IntuneUserId, CmdbEntraObjectId, Outcome, Reason

    From the repository root, the default fixtures produce Match, Unresolved/
    CmdbAssetMissing, and Unresolved/CmdbAssetAmbiguous, in device order.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]] $InputObject,

        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]] $CmdbAsset,

        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]] $PersonMapping,

        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]] $EntraUser
    )

    process {
        foreach ($correlation in (Resolve-ParIntuneDeviceCmdbAsset -InputObject $InputObject -CmdbAsset $CmdbAsset)) {
            $device = $correlation.IntuneDevice
            $intuneUserId = ([string] $device.UserId).Trim()
            $resolution = $null
            $cmdbEntraObjectId = $null
            $comparisonCmdbId = $null
            $outcome = 'Unresolved'
            $reason = 'CmdbAssetMissing'

            if ($correlation.Outcome -eq 'Ambiguous') {
                $reason = 'CmdbAssetAmbiguous'
            }
            elseif ($correlation.Outcome -eq 'Unique') {
                $resolution = Resolve-ParCmdbAssignedUser -InputObject $correlation.CmdbCandidates[0] -PersonMapping $PersonMapping -EntraUser $EntraUser
                $reason = 'CmdbAssignedUserUnresolved'

                if ($resolution.Outcome -eq 'Unique') {
                    $cmdbEntraObjectId = $resolution.EntraObjectId
                    $comparisonCmdbId = ([string] $cmdbEntraObjectId).Trim()
                    if ($intuneUserId -eq '') {
                        $outcome = 'MissingAssignment'
                        $reason = 'IntuneAssignmentMissing'
                    }
                    elseif ($intuneUserId -ieq $comparisonCmdbId) {
                        $outcome = 'Match'
                        $reason = 'SameUserId'
                    }
                    else {
                        $outcome = 'Mismatch'
                        $reason = 'DifferentUserIds'
                    }
                }
                elseif ($resolution.Reason -eq 'BlankAssignedUserReference') {
                    $outcome = 'MissingAssignment'
                    $reason = 'CmdbAssignmentMissing'
                    if ($intuneUserId -eq '') {
                        $reason = 'BothAssignmentsMissing'
                    }
                }
            }

            [pscustomobject][ordered]@{
                IntuneDeviceId = $device.Id
                IntuneDevice = $device
                IntuneUserId = $device.UserId
                CmdbEntraObjectId = $cmdbEntraObjectId
                ComparisonIntuneUserId = $intuneUserId
                ComparisonCmdbEntraObjectId = $comparisonCmdbId
                Outcome = $outcome
                Reason = $reason
                Correlation = $correlation
                AssignedUserResolution = $resolution
            }
        }
    }
}
