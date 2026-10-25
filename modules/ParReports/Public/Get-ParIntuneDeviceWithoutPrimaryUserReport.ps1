function Get-ParIntuneDeviceWithoutPrimaryUserReport {
    <#
    .SYNOPSIS
    Retrieves a report of Windows Intune devices with a missing primary-user association.
    .DESCRIPTION
    Retrieves source objects through ParData's Get-ParIntuneDevice and transforms
    the completed dataset. Uses ParData's existing configuration and development
    defaults. Retrieval errors terminate the call before any report rows are emitted.
    No authentication or Graph requests are performed by the current provider.
    Missing association is descriptive, not automatically a defect.
    Calls Get-ParIntuneDevice once per invocation. An explicitly configured
    ParData import is retained; the query does not force a reimport or introduce
    report-specific fixture paths. Both terminating and nonterminating retrieval
    errors terminate the query. Even if retrieval emits objects before failing,
    no partial report is emitted.
    .INPUTS
    None

    Pipeline input is not accepted.
    .OUTPUTS
    System.Management.Automation.PSCustomObject

    The rows documented by ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport.
    Zero rows means retrieval succeeded with no matching devices.
    .EXAMPLE
    Import-Module ./modules/ParReports/ParReports.psd1
    $report = @(Get-ParIntuneDeviceWithoutPrimaryUserReport)
    .NOTES
    See ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport help for selection and
    output fields. The documentation index routes to configuration and errata.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    Import-Module (Join-Path $PSScriptRoot '../../ParData/ParData.psd1') -ErrorAction Stop
    $devices = @(Get-ParIntuneDevice -ErrorAction Stop)
    ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport -InputObject $devices
}
