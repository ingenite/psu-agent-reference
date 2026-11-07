@{
    RootModule = 'ParVolumeReport.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'af7f21b6-c79e-47b0-b1cf-50eb92cc127b'
    Author = 'PAR'
    Description = 'Small volume-space example showing software-design principles across PSU resources.'
    PowerShellVersion = '7.4'
    FunctionsToExport = @('Get-ParDemoVolume', 'Get-ParVolumeAssessment', 'Get-ParVolumeReport')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
