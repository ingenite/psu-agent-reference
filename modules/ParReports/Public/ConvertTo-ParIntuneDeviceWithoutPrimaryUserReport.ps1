function ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport {
    <#
    .SYNOPSIS
    Reports Windows Intune devices with a missing primary-user association.
    .DESCRIPTION
    Transforms supplied source objects without retrieval or source mutation.
    Matches operatingSystem equal to Windows (case-insensitive) and userId null,
    empty, or whitespace. Display name, email, and UPN do not affect selection.
    Missing association is descriptive; intentionally userless devices may match.
    Emits rows in source order without deduplication. Empty or null input emits
    no rows. Enrollment type is text; other selected source values are preserved.
    Matching does not use enrollment type, device name, or the Graph primary-user
    relationship. Nonblank userId excludes a device even if display fields are
    empty. Null or blank OS values and OS labels other than Windows do not match.
    Does not calculate staleness, resolve users, generate links, or assign severity.
    .PARAMETER InputObject
    Managed-device source objects with the properties returned by Get-ParIntuneDevice.
    Accepts an array or pipeline input. Null objects are ignored.
    Non-null objects must expose the properties used by the report; incomplete
    source models are not repaired. Equivalent supplied objects can be used for
    isolated tests without loading Graph.
    .INPUTS
    System.Object[]

    Source device objects supplied individually through the pipeline or as an array.
    .OUTPUTS
    System.Management.Automation.PSCustomObject

    Each match produces a new object with these fields:
    IntuneDeviceId: source Id, identifying the Intune record.
    AzureAdDeviceId: source Entra device ID, distinct from the Intune record ID.
    DeviceName, SerialNumber, Manufacturer, Model: source identity and hardware.
    OperatingSystem, OSVersion: source OS values.
    DeviceEnrollmentType: source enrollment type as text, empty when absent.
    EnrolledDateTime: source enrollment timestamp, preserving null.
    LastSyncDateTime: source last successful sync timestamp, preserving null.
    UserId: original missing association, preserving null, empty, or whitespace.
    Timestamps retain their source types and values. Input order and duplicates
    are preserved; null input, empty arrays, and empty pipelines emit no rows.
    .EXAMPLE
    $devices | ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport
    .EXAMPLE
    ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport -InputObject $devices
    .NOTES
    The documentation index routes to the report example and project errata.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]] $InputObject
    )

    process {
        foreach ($device in $InputObject) {
            if ($null -eq $device) {
                continue
            }

            if ($device.OperatingSystem -eq 'Windows' -and ([string] $device.UserId).Trim() -eq '') {
                [pscustomobject][ordered]@{
                    IntuneDeviceId = $device.Id
                    AzureAdDeviceId = $device.AzureAdDeviceId
                    DeviceName = $device.DeviceName
                    SerialNumber = $device.SerialNumber
                    Manufacturer = $device.Manufacturer
                    Model = $device.Model
                    OperatingSystem = $device.OperatingSystem
                    OSVersion = $device.OSVersion
                    DeviceEnrollmentType = [string] $device.DeviceEnrollmentType
                    EnrolledDateTime = $device.EnrolledDateTime
                    LastSyncDateTime = $device.LastSyncDateTime
                    UserId = $device.UserId
                }
            }
        }
    }
}
