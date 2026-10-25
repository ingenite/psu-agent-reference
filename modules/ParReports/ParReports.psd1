@{
    RootModule = 'ParReports.psm1'
    ModuleVersion = '0.1.0'
    GUID = '430f4cc8-f2ad-4e28-88b1-eb9f56192873'
    Author = 'PAR'
    Description = 'Shared reports and source-object transformations for PSU scripts, endpoints, and dashboards.'
    PowerShellVersion = '7.1'
    FunctionsToExport = @(
        'Get-ParIntuneDeviceWithoutPrimaryUserReport'
        'ConvertTo-ParIntuneDeviceWithoutPrimaryUserReport'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
