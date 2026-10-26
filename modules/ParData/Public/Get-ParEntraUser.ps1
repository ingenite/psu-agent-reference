function Get-ParEntraUser {
    <#
    .SYNOPSIS
    Returns Entra user SDK models from the configured offline fixture.
    .DESCRIPTION
    Uses the EntraUser fixture path selected when ParData was imported: explicit
    -ArgumentList paths override global PAR_FixturePaths, then repository defaults.
    Loads Microsoft.Graph.Users 2.41.2 only when called. Importing ParData alone
    does not require Graph. No authentication or service requests are performed.
    Each call reads the current UTF-8 file literally and creates or modifies no files.

    Requires exactly id, displayName, userPrincipalName, mail, accountEnabled as
    case-sensitive headers, each once, in any order. Quoted commas, doubled quotes,
    multiline cells, LF/CRLF separators, and an optional final newline are accepted.
    Zero-byte, whitespace-only, and valid header-only files return no objects.
    id and displayName must be nonblank. Empty optional cells become null; all
    nonempty strings are preserved without trimming or identity inference.
    accountEnabled accepts only True or False (case-insensitive) or an empty cell
    for null. Padded values, numbers, and other nonempty text are invalid.

    Preserves supplied IDs, stored order, and duplicate records. Missing/unreadable
    files, incompatible headers, malformed CSV, and invalid values terminate before
    any users are emitted. Record-value errors include the path and one-based data
    record number, including when quoted cells span lines. All records are restored
    before output. CSV cannot distinguish an original empty string from null.
    .INPUTS
    None

    Pipeline input is not accepted.
    .OUTPUTS
    Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser

    Zero or more actual SDK user models. Wrap the call in @() for a collection.
    .EXAMPLE
    Import-Module ./modules/ParData/ParData.psd1
    $users = @(Get-ParEntraUser)
    #>
    [CmdletBinding()]
    [OutputType('Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser')]
    param()

    Import-Module Microsoft.Graph.Users -RequiredVersion '2.41.2' -ErrorAction Stop

    $path = $script:SourceFixturePaths.EntraUser
    $columns = @('id', 'displayName', 'userPrincipalName', 'mail', 'accountEnabled')
    $rows = @(Read-ParFixtureCsv -Path $path -SourceDescription 'Entra user' -Columns $columns)
    $recordNumber = 0
    $users = @(
        foreach ($row in $rows) {
            $recordNumber++
            try {
                foreach ($propertyName in @('id', 'displayName')) {
                    if ($row.$propertyName.Trim() -eq '') {
                        throw "$propertyName must not be blank."
                    }
                }

                $properties = [ordered]@{}
                foreach ($column in $columns) {
                    $value = $row.$column
                    if ($value -eq '') {
                        $value = $null
                    }
                    elseif ($column -eq 'accountEnabled') {
                        $value = switch ($value) {
                            'True' { $true }
                            'False' { $false }
                            default { throw 'accountEnabled must be True or False (case-insensitive), or empty.' }
                        }
                    }
                    $properties[$column] = $value
                }

                $json = ConvertTo-Json -InputObject $properties -Depth 3
                # Session approval covers offline Graph user construction through JSON deserialization.
                [Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser]::FromJsonString($json)
            }
            catch {
                throw "Invalid Entra user fixture '$path', data record ${recordNumber}: $($_.Exception.Message)"
            }
        }
    )

    $users
}
