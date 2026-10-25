function Get-ParIntuneDevice {
    <#
    .SYNOPSIS
    Returns Intune managed-device SDK models from the configured offline fixture.
    .DESCRIPTION
    Uses global PAR_FixturePaths when present, with repository-relative defaults
    outside PSU. Explicit import configuration through -ArgumentList takes precedence.
    Returns no objects for an empty dataset. Invalid fixtures terminate before any
    devices are emitted. No authentication or Graph requests are performed.
    .EXAMPLE
    Import-Module ./modules/ParData/ParData.psd1
    $devices = @(Get-ParIntuneDevice)
    #>
    [CmdletBinding()]
    [OutputType('Microsoft.Graph.PowerShell.Models.IMicrosoftGraphManagedDevice')]
    param()

    Import-Module Microsoft.Graph.DeviceManagement -RequiredVersion '2.41.2' -ErrorAction Stop

    $path = $script:SourceFixturePaths.IntuneDevice
    try {
        $csv = Get-Content -LiteralPath $path -Raw -Encoding utf8 -ErrorAction Stop
    }
    catch {
        throw "Cannot read Intune device fixture '$path': $($_.Exception.Message)"
    }

    if ($null -eq $csv -or $csv.Trim() -eq '') {
        return
    }

    $columns = @(
        'id', 'userId', 'deviceName', 'enrolledDateTime', 'lastSyncDateTime',
        'operatingSystem', 'osVersion', 'emailAddress', 'azureADDeviceId',
        'userPrincipalName', 'model', 'manufacturer', 'serialNumber',
        'userDisplayName', 'deviceEnrollmentType'
    )

    # Native CSV conversion tolerates broken quotes and surplus cells; validate structure first.
    # Quoted cells may contain commas, doubled quotes, and line breaks.
    $cellPattern = '(?:"(?:[^"]|"")*"|[^",\r\n]*)'
    $recordPattern = "$cellPattern(?:,$cellPattern){14}"
    if ($csv -cnotmatch "\A$recordPattern(?:\r?\n$recordPattern)*(?:\r?\n)?\z") {
        throw "Invalid Intune device fixture '$path': expected CSV records with 15 cells and balanced quotes."
    }

    $header = $csv | ConvertFrom-Csv -Header $columns | Select-Object -First 1
    $headerNames = @($header.PSObject.Properties.Value)
    if (Compare-Object -ReferenceObject $columns -DifferenceObject $headerNames -CaseSensitive) {
        throw "Incompatible Intune device fixture '$path': expected the exporter's 15 column names, each exactly once."
    }

    $rows = @($csv | ConvertFrom-Csv)
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
