function Get-ParCmdbPersonMapping {
    <#
    .SYNOPSIS
    Returns explicit CMDB person-to-UPN mappings from the configured offline fixture.
    .DESCRIPTION
    Uses the PersonMapping path selected when ParData was imported: explicit
    -ArgumentList paths override global PAR_FixturePaths, then the repository
    default data/cmdb-person-mappings.csv. Reads the current UTF-8 file literally
    on each call. Requires no Graph modules, authentication, or external requests.
    Creates or modifies no files.

    Requires exactly personReference and userPrincipalName as case-sensitive CSV
    headers, each once, in any order. Accepts quoted commas, doubled quotes,
    multiline cells, LF/CRLF, and an optional final newline. Zero-byte,
    whitespace-only, and valid header-only files return no objects.
    Empty cells become null; all nonempty strings, order, and duplicate rows are
    preserved. Blank references or UPNs are allowed as source evidence; their
    meaning belongs to Resolve-ParCmdbAssignedUser. No lookup or inference occurs.
    CSV cannot distinguish an original null from an empty string.

    Missing or unreadable files, incompatible headers, and malformed CSV terminate
    before any mappings are emitted. The complete file is validated and restored
    before output. These mappings are supplied demonstration assertions, not
    independently verified identities.
    .INPUTS
    None

    Pipeline input is not accepted.
    .OUTPUTS
    System.Management.Automation.PSCustomObject

    Zero or more plain objects exposing personReference and userPrincipalName,
    in that order, with string or null values. Wrap the call in @() for an array.
    .EXAMPLE
    Import-Module ./modules/ParData/ParData.psd1
    $mappings = @(Get-ParCmdbPersonMapping)
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $rows = @(Read-ParFixtureCsv -Path $script:SourceFixturePaths.PersonMapping -SourceDescription 'CMDB person mapping' -Columns @('personReference', 'userPrincipalName'))
    $mappings = @(
        foreach ($row in $rows) {
            [pscustomobject][ordered]@{
                personReference = if ($row.personReference -eq '') { $null } else { $row.personReference }
                userPrincipalName = if ($row.userPrincipalName -eq '') { $null } else { $row.userPrincipalName }
            }
        }
    )
    $mappings
}
