function Resolve-ParCmdbAssignedUser {
    <#
    .SYNOPSIS
    Resolves CMDB assigned-person references to Entra user IDs through a UPN mapping.
    .DESCRIPTION
    Transforms supplied objects without retrieval, source mutation, or external
    requests. Uses one explicit rule: assignedUserReference on a CMDB asset matches
    personReference on a supplied mapping row; that row's userPrincipalName matches
    UserPrincipalName on an Entra user. UPN is the chosen account attribute because
    it ordinarily identifies one account. Expected uniqueness is checked against
    supplied records rather than assumed. Mail, display names, account state, and
    Intune assignments do not affect resolution. Person references are opaque;
    their suffixes are never interpreted as UPNs or Entra IDs.

    Both comparisons use Trim() and PowerShell case-insensitive literal equality
    (-ieq). Internal whitespace and punctuation remain significant. Null, empty,
    and whitespace-only keys never match, including each other. Only comparison
    values are trimmed; original source values and the resolved ID are preserved.

    Resolution requires exactly one mapping row, exactly one Entra candidate, and
    a nonblank candidate Id. Duplicate rows remain ambiguous even when they contain
    identical references, UPNs, or IDs. No deduplication or tie-breaking occurs.
    Entra matching is attempted only after one mapping with a nonblank UPN exists.

    Outcome/Reason combinations:
    Missing/BlankAssignedUserReference: the asset has no usable person reference.
    Missing/NoPersonMapping: no mapping row matches the reference.
    Ambiguous/MultiplePersonMappings: more than one mapping row matches.
    Missing/BlankMappedUserPrincipalName: the single mapping has no usable UPN.
    Missing/NoMatchingEntraUser: no Entra user matches that UPN.
    Ambiguous/MultipleMatchingEntraUsers: more than one Entra record matches.
    Missing/BlankEntraObjectId: the single candidate has no usable Id.
    Unique/OneMappedEntraUser: the ID can be returned under the supplied mapping.

    Emits one result per non-null asset in input order, retaining repeated records.
    Each asset is evaluated independently; candidates are not consumed. Unique
    means unique within the supplied datasets under this rule. The mapping is an
    explicit assertion supplied by the caller, not independently verified identity.
    .PARAMETER InputObject
    CMDB objects exposing assetId and assignedUserReference, as returned by
    Get-ParCmdbAsset. Accepts an array or pipeline input. Null elements are ignored;
    null input, empty arrays, and empty pipelines emit no results.
    .PARAMETER PersonMapping
    Plain mapping objects exposing personReference and userPrincipalName as strings
    or null. Supply the complete dataset. Import-Csv can read the demonstration
    data/cmdb-person-mappings.csv directly; no ParData provider is required.
    Blank references never match. A matched blank UPN produces a Missing result.
    Null elements are ignored; null or empty datasets contain no mappings.
    .PARAMETER EntraUser
    Entra objects exposing Id and UserPrincipalName, as returned by Get-ParEntraUser.
    Supply the complete candidate dataset. Blank UPNs never match. Null elements
    are ignored; null or empty datasets contain no candidates. Equivalent plain
    objects support offline examples without Graph. Non-null inputs must expose
    the documented properties with string or null values; malformed objects are
    not repaired and missing properties terminate under module strict mode.
    .INPUTS
    System.Object[]

    CMDB asset source objects, individually or as an array.
    .OUTPUTS
    System.Management.Automation.PSCustomObject

    CmdbAssetId, CmdbAsset: original asset ID and source object.
    AssignedUserReference: original reference, preserving null/empty/whitespace.
    ComparisonPersonReference: trimmed reference; empty for a blank reference.
    MappingCount, MappingCandidates: count and array of all matching original
    mapping rows in supplied order, including duplicates.
    ComparisonUserPrincipalName: trimmed mapped UPN; null unless one mapping row
    exists, empty if that row's UPN is blank.
    EntraCandidateCount, EntraCandidates: count and array of matching original
    Entra records in supplied order, including duplicates. Zero/empty when Entra
    matching is not attempted; Reason distinguishes that from no matching user.
    EntraObjectId: original candidate Id only for Unique; null otherwise.
    Outcome, Reason: values described above.

    Source objects are references, not copies. This command leaves them unchanged;
    consumers must not mutate them through results if retaining source evidence.
    .EXAMPLE
    Import-Module ./modules/ParData/ParData.psd1
    Import-Module ./modules/ParReports/ParReports.psd1
    $assets = @(Get-ParCmdbAsset)
    $users = @(Get-ParEntraUser)
    $mappings = @(Import-Csv -LiteralPath ./data/cmdb-person-mappings.csv)
    $results = @($assets | Resolve-ParCmdbAssignedUser -PersonMapping $mappings -EntraUser $users)
    $results | Select-Object CmdbAssetId, AssignedUserReference, Outcome, Reason, EntraObjectId

    From the repository root, the fixtures resolve CMDB-PERSON-001 to Alex's ID
    and CMDB-PERSON-002 to Blair's ID. CMDB-ASSET-003 has a blank reference and
    remains Missing. Blair's disabled account state does not change resolution.
    .EXAMPLE
    Import-Module ./modules/ParReports/ParReports.psd1
    $assets = @(
        [pscustomobject]@{ assetId = 'CMDB-DEMO-1'; assignedUserReference = 'CMDB-PERSON-1' }
        [pscustomobject]@{ assetId = 'CMDB-DEMO-2'; assignedUserReference = 'CMDB-PERSON-2' }
        [pscustomobject]@{ assetId = 'CMDB-DEMO-3'; assignedUserReference = 'CMDB-PERSON-3' }
    )
    $mappings = @(
        [pscustomobject]@{ personReference = 'CMDB-PERSON-1'; userPrincipalName = 'alex@example.invalid' }
        [pscustomobject]@{ personReference = 'CMDB-PERSON-3'; userPrincipalName = 'duplicate@example.invalid' }
    )
    $users = @(
        [pscustomobject]@{ Id = 'ENTRA-DEMO-1'; UserPrincipalName = 'alex@example.invalid' }
        [pscustomobject]@{ Id = 'ENTRA-DEMO-2'; UserPrincipalName = 'duplicate@example.invalid' }
        [pscustomobject]@{ Id = 'ENTRA-DEMO-3'; UserPrincipalName = 'DUPLICATE@example.invalid' }
    )
    $results = @(Resolve-ParCmdbAssignedUser -InputObject $assets -PersonMapping $mappings -EntraUser $users)
    $results | Select-Object CmdbAssetId, Outcome, Reason, MappingCount, EntraCandidateCount
    $results[2].MappingCandidates
    $results[2].EntraCandidates

    Deterministically produces Unique/OneMappedEntraUser, Missing/NoPersonMapping,
    and Ambiguous/MultipleMatchingEntraUsers, retaining both duplicate candidates.
    Supplying -PersonMapping @($mappings[0], $mappings[0]) instead makes the first
    asset Ambiguous/MultiplePersonMappings even though the mapping rows agree.
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
        [object[]] $PersonMapping,

        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]] $EntraUser
    )

    begin {
        $comparableMappings = @(
            foreach ($mapping in $PersonMapping) {
                if ($null -eq $mapping) {
                    continue
                }

                $reference = ([string] $mapping.personReference).Trim()
                if ($reference -ne '') {
                    [pscustomobject]@{
                        Mapping = $mapping
                        PersonReference = $reference
                    }
                }
            }
        )
        $comparableUsers = @(
            foreach ($user in $EntraUser) {
                if ($null -eq $user) {
                    continue
                }

                $upn = ([string] $user.UserPrincipalName).Trim()
                if ($upn -ne '') {
                    [pscustomobject]@{
                        User = $user
                        UserPrincipalName = $upn
                    }
                }
            }
        )
    }

    process {
        foreach ($asset in $InputObject) {
            if ($null -eq $asset) {
                continue
            }

            $reference = ([string] $asset.assignedUserReference).Trim()
            $mappingCandidates = @(
                if ($reference -ne '') {
                    foreach ($comparableMapping in $comparableMappings) {
                        if ($reference -ieq $comparableMapping.PersonReference) {
                            $comparableMapping.Mapping
                        }
                    }
                }
            )
            $upn = $null
            $entraCandidates = @()
            $entraObjectId = $null
            $outcome = 'Missing'
            $reason = 'NoPersonMapping'

            if ($reference -eq '') {
                $reason = 'BlankAssignedUserReference'
            }
            elseif ($mappingCandidates.Count -gt 1) {
                $outcome = 'Ambiguous'
                $reason = 'MultiplePersonMappings'
            }
            elseif ($mappingCandidates.Count -eq 1) {
                $upn = ([string] $mappingCandidates[0].userPrincipalName).Trim()
                $reason = 'BlankMappedUserPrincipalName'
                if ($upn -ne '') {
                    $entraCandidates = @(
                        foreach ($comparableUser in $comparableUsers) {
                            if ($upn -ieq $comparableUser.UserPrincipalName) {
                                $comparableUser.User
                            }
                        }
                    )
                    $reason = 'NoMatchingEntraUser'
                    if ($entraCandidates.Count -gt 1) {
                        $outcome = 'Ambiguous'
                        $reason = 'MultipleMatchingEntraUsers'
                    }
                    elseif ($entraCandidates.Count -eq 1) {
                        $reason = 'BlankEntraObjectId'
                        if (([string] $entraCandidates[0].Id).Trim() -ne '') {
                            $outcome = 'Unique'
                            $reason = 'OneMappedEntraUser'
                            $entraObjectId = $entraCandidates[0].Id
                        }
                    }
                }
            }

            [pscustomobject][ordered]@{
                CmdbAssetId = $asset.assetId
                CmdbAsset = $asset
                AssignedUserReference = $asset.assignedUserReference
                ComparisonPersonReference = $reference
                MappingCount = $mappingCandidates.Count
                MappingCandidates = $mappingCandidates
                ComparisonUserPrincipalName = $upn
                EntraCandidateCount = $entraCandidates.Count
                EntraCandidates = $entraCandidates
                EntraObjectId = $entraObjectId
                Outcome = $outcome
                Reason = $reason
            }
        }
    }
}
