@{
    RootModule = 'ParData.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'baebcfe2-b53a-4684-8892-3ddf9cce3524'
    Author = 'PAR'
    Description = 'Shared source-data retrieval commands for PSU scripts, endpoints, and dashboards.'
    PowerShellVersion = '7.1'
    FunctionsToExport = @('Get-ParIntuneDevice', 'Get-ParEntraUser', 'Get-ParCmdbAsset', 'Get-ParCmdbPersonMapping')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
