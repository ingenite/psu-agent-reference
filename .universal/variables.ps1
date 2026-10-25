New-PSUVariable -Name 'PAR_FixturePaths' -Scope Global -Description 'Synthetic source fixture locations shared by PSU resources.' -InputObject @{
    IntuneDevice = (Join-Path $PSScriptRoot '../data/intune-devices.csv')
}
