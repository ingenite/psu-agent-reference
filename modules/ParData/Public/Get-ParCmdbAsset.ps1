function Get-ParCmdbAsset {
    <#
    .SYNOPSIS
    Returns plain PowerShell CMDB assets from the configured offline fixture.
    .DESCRIPTION
    Uses the CmdbAsset fixture path selected when ParData was imported: explicit
    -ArgumentList paths override global PAR_FixturePaths, then repository defaults.
    Requires no Graph modules, authentication, or service requests. Each call reads
    the current UTF-8 file literally and creates or modifies no files.

    Requires exactly assetId, assetTag, deviceName, serialNumber,
    assignedUserReference as case-sensitive headers, each once, in any order.
    Quoted commas, doubled quotes, multiline cells, LF/CRLF separators, and an
    optional final newline are accepted. Zero-byte, whitespace-only, and valid
    header-only files return no objects. assetId must be nonblank. Empty optional
    cells become null; nonempty strings are preserved without trimming or inference.
    CSV cannot distinguish an original empty string from null.

    Preserves supplied IDs, stored order, and duplicate records. assignedUserReference
    remains an opaque CMDB person reference; no Entra mapping or device correlation
    is performed. Missing/unreadable files, incompatible headers, malformed CSV,
    and invalid values terminate before any assets are emitted. Record-value errors
    include the path and one-based data record number, including when quoted cells
    span lines. All records are restored before output.
    .INPUTS
    None

    Pipeline input is not accepted.
    .OUTPUTS
    System.Management.Automation.PSCustomObject

    Zero or more plain source objects with assetId, assetTag, deviceName,
    serialNumber, assignedUserReference in that order. Non-null values are strings.
    Wrap the call in @() for a collection.
    .EXAMPLE
    Import-Module ./modules/ParData/ParData.psd1
    $assets = @(Get-ParCmdbAsset)
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $path = $script:SourceFixturePaths.CmdbAsset
    $columns = @('assetId', 'assetTag', 'deviceName', 'serialNumber', 'assignedUserReference')
    $rows = @(Read-ParFixtureCsv -Path $path -SourceDescription 'CMDB asset' -Columns $columns)
    $recordNumber = 0
    $assets = @(
        foreach ($row in $rows) {
            $recordNumber++
            try {
                if ($row.assetId.Trim() -eq '') {
                    throw 'assetId must not be blank.'
                }
                $properties = [ordered]@{}
                foreach ($column in $columns) {
                    $value = $row.$column
                    $properties[$column] = if ($value -eq '') { $null } else { $value }
                }
                [pscustomobject] $properties
            }
            catch {
                throw "Invalid CMDB asset fixture '$path', data record ${recordNumber}: $($_.Exception.Message)"
            }
        }
    )

    $assets
}
