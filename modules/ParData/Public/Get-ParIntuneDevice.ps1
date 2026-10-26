function Get-ParIntuneDevice {
    <#
    .SYNOPSIS
    Returns Intune managed-device SDK models from the configured offline fixture.
    .DESCRIPTION
    Uses global PAR_FixturePaths when present, with repository-relative defaults
    outside PSU. Explicit import configuration through -ArgumentList takes precedence.
    Returns no objects for an empty dataset. Invalid fixtures terminate before any
    devices are emitted. No authentication or Graph requests are performed.
    Loads Microsoft.Graph.DeviceManagement 2.41.2 when called. Importing ParData
    alone does not require Graph. Each call reads the configured file literally;
    retrieval creates or modifies no files.

    Requires these 15 case-sensitive column names, each exactly once, in any order:
    id, userId, deviceName, enrolledDateTime, lastSyncDateTime, operatingSystem,
    osVersion, emailAddress, azureADDeviceId, userPrincipalName, model, manufacturer,
    serialNumber, userDisplayName, deviceEnrollmentType. Accepts UTF-8 CSV, quoted
    commas, doubled quotes, multiline cells, LF/CRLF separators, and an optional final
    newline. Zero-byte, whitespace-only, and valid header-only files return no objects.
    Blank records within a nonempty fixture are invalid.

    id and deviceName must be nonblank. Identifiers remain opaque strings. Empty
    userId, emailAddress, userPrincipalName, and userDisplayName cells become null.
    Other string cells retain their values, including whitespace and empty hardware
    strings. CSV cannot distinguish an original null from an empty string.
    Empty timestamps become null; nonempty timestamps must be valid ISO 8601 with
    Z or a numeric offset and at most seven fractional digits. They normalize to UTC
    before deserialization. Empty deviceEnrollmentType is omitted; nonempty text is
    passed unchanged to the SDK's extensible enum.

    Returns all records in stored order without filtering, deduplication, or
    assignment interpretation. Missing or unreadable files, malformed CSV,
    incompatible headers, and invalid records raise terminating errors. All records
    are restored before output, so a bad later record emits no partial dataset.
    Record errors identify the path and one-based data-record number, including
    when quoted cells span lines.
    .INPUTS
    None

    Pipeline input is not accepted.
    .OUTPUTS
    Microsoft.Graph.PowerShell.Models.IMicrosoftGraphManagedDevice

    Zero or more actual SDK managed-device models. Consumers depend on the source
    model, not CSV rows or report fields. Wrap the call in @() for a collection.
    .EXAMPLE
    Import-Module ./modules/ParData/ParData.psd1
    $devices = @(Get-ParIntuneDevice)
    #>
    [CmdletBinding()]
    [OutputType('Microsoft.Graph.PowerShell.Models.IMicrosoftGraphManagedDevice')]
    param()

    Import-Module Microsoft.Graph.DeviceManagement -RequiredVersion '2.41.2' -ErrorAction Stop

    $path = $script:SourceFixturePaths.IntuneDevice
    $columns = @(
        'id', 'userId', 'deviceName', 'enrolledDateTime', 'lastSyncDateTime',
        'operatingSystem', 'osVersion', 'emailAddress', 'azureADDeviceId',
        'userPrincipalName', 'model', 'manufacturer', 'serialNumber',
        'userDisplayName', 'deviceEnrollmentType'
    )

    $rows = @(Read-ParFixtureCsv -Path $path -SourceDescription 'Intune device' -Columns $columns)
    $recordNumber = 0
    $devices = @(
        foreach ($row in $rows) {
            $recordNumber++
            try {
                foreach ($propertyName in @('id', 'deviceName')) {
                    if ($row.$propertyName.Trim() -eq '') {
                        throw "$propertyName must not be blank."
                    }
                }

                $properties = [ordered]@{}
                foreach ($column in $columns) {
                    $value = $row.$column
                    if ($column -in @('userId', 'emailAddress', 'userPrincipalName', 'userDisplayName') -and $value -eq '') {
                        $value = $null
                    }
                    elseif ($column -in @('enrolledDateTime', 'lastSyncDateTime')) {
                        if ($value -eq '') {
                            $value = $null
                        }
                        else {
                            if ($value -cnotmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?(?:Z|[+-]\d{2}:\d{2})$') {
                                throw "$column must be an ISO 8601 timestamp with an explicit time zone, or empty."
                            }
                            $timestamp = [datetimeoffset] $value
                            $value = $timestamp.UtcDateTime.ToString('o')
                        }
                    }
                    elseif ($column -eq 'deviceEnrollmentType' -and $value -eq '') {
                        continue
                    }
                    $properties[$column] = $value
                }

                $json = ConvertTo-Json -InputObject $properties -Depth 3
                # Owner authorized FromJsonString for fixture restoration in this implementation and its tests.
                [Microsoft.Graph.PowerShell.Models.MicrosoftGraphManagedDevice]::FromJsonString($json)
            }
            catch {
                throw "Invalid Intune device fixture '$path', data record ${recordNumber}: $($_.Exception.Message)"
            }
        }
    )

    $devices
}
