function Read-ParFixtureCsv {
    [CmdletBinding()]
    param(
        [string] $Path,
        [string] $SourceDescription,
        [string[]] $Columns
    )

    try {
        $csv = Get-Content -LiteralPath $Path -Raw -Encoding utf8 -ErrorAction Stop
    }
    catch {
        throw "Cannot read $SourceDescription fixture '$Path': $($_.Exception.Message)"
    }
    if ($null -eq $csv -or $csv.Trim() -eq '') {
        return
    }

    # Validate structure before decoding; native CSV conversion tolerates malformed input.
    $cellPattern = '(?:"(?:[^"]|"")*"|[^",\r\n]*)'
    $recordPattern = "$cellPattern(?:,$cellPattern){$($Columns.Count - 1)}"
    if ($csv -cnotmatch "\A$recordPattern(?:\r?\n$recordPattern)*(?:\r?\n)?\z") {
        throw "Invalid $SourceDescription fixture '$Path': expected CSV records with $($Columns.Count) cells and balanced quotes."
    }

    # Split only outside quoted cells. Decode directly to preserve unquoted whitespace too.
    $records = $csv -split '\r?\n(?=(?:[^"]*"[^"]*")*[^"]*$)'
    $headerNames = $null
    foreach ($record in $records) {
        if ($record -eq '') { continue } # Optional final newline; internal blank records failed validation.
        $cells = @(
            foreach ($cell in ($record -split ',(?=(?:[^"]*"[^"]*")*[^"]*$)')) {
                if ($cell.StartsWith('"')) {
                    $cell.Substring(1, $cell.Length - 2).Replace('""', '"')
                }
                else {
                    $cell
                }
            }
        )
        if ($null -eq $headerNames) {
            $headerNames = $cells
            if (Compare-Object -ReferenceObject $Columns -DifferenceObject $headerNames -CaseSensitive) {
                throw "Incompatible $SourceDescription fixture '$Path': expected the exporter's $($Columns.Count) column names, each exactly once."
            }
            continue
        }

        $properties = [ordered]@{}
        for ($columnIndex = 0; $columnIndex -lt $Columns.Count; $columnIndex++) {
            $properties[$headerNames[$columnIndex]] = $cells[$columnIndex]
        }
        [pscustomobject] $properties
    }
}
