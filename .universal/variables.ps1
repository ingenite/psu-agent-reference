$fixturePaths = @{
    IntuneDevice = (Join-Path $PSScriptRoot '../data/intune-devices.csv')
    EntraUser = (Join-Path $PSScriptRoot '../data/entra-users.csv')
    CmdbAsset = (Join-Path $PSScriptRoot '../data/cmdb-assets.csv')
    PersonMapping = (Join-Path $PSScriptRoot '../data/cmdb-person-mappings.csv')
}
# Store structured configuration as JSON text so PSU injection does not depend on object serialization.
New-PSUVariable -Name 'PAR_FixturePaths' -Scope Global -Description 'Synthetic source fixture locations as JSON, shared by PSU resources.' -Value ($fixturePaths | ConvertTo-Json -Compress)
