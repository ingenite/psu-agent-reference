function Get-ParDemoVolume {
    <#
    .SYNOPSIS
    Returns three synthetic volumes without reading any disks.
    .DESCRIPTION
    Supplies the default reader for Get-ParVolumeReport. Every invocation returns
    new objects; no files, services, credentials, or PSU configuration are used.
    .INPUTS
    None
    .OUTPUTS
    PSCustomObject with Name, CapacityGB, and FreeGB.
    .EXAMPLE
    Get-ParDemoVolume
    Returns volumes with 10, 20, and 60 percent free space.
    #>
    [CmdletBinding()]
    param()

    [pscustomobject]@{ Name = 'Demo-C'; CapacityGB = 100; FreeGB = 10 }
    [pscustomobject]@{ Name = 'Demo-D'; CapacityGB = 200; FreeGB = 40 }
    [pscustomobject]@{ Name = 'Demo-E'; CapacityGB = 100; FreeGB = 60 }
}

function Get-ParVolumeAssessment {
    <#
    .SYNOPSIS
    Assesses supplied volumes using an explicit free-space threshold.
    .DESCRIPTION
    Pure calculation: reads only its parameters and returns new objects without
    changing the input. Below the threshold is Low; equality is OK. Input order
    is preserved. An empty collection produces no output.
    .PARAMETER Volume
    Objects with Name, CapacityGB, and FreeGB. The reader must supply numeric
    values with CapacityGB greater than zero and FreeGB between zero and capacity.
    These trusted-input assumptions keep this example focused on design.
    .PARAMETER MinimumFreePercent
    Lowest acceptable percentage, from 0 through 100. No hidden default applies.
    .INPUTS
    None. Supply volumes through -Volume.
    .OUTPUTS
    PSCustomObject with Name, FreePercent, and Status (Low or OK).
    FreePercent is the calculated value without display rounding.
    .EXAMPLE
    Get-ParVolumeAssessment -Volume (Get-ParDemoVolume) -MinimumFreePercent 20
    Returns Low, OK, and OK for the demonstration volumes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]] $Volume,

        [Parameter(Mandatory)]
        [ValidateRange(0, 100)]
        [int] $MinimumFreePercent
    )

    foreach ($item in $Volume) {
        $freePercent = 100 * $item.FreeGB / $item.CapacityGB
        [pscustomobject]@{
            Name = $item.Name
            FreePercent = $freePercent
            Status = if ($freePercent -lt $MinimumFreePercent) { 'Low' } else { 'OK' }
        }
    }
}

function Get-ParVolumeReport {
    <#
    .SYNOPSIS
    Reads volumes once, then applies the shared assessment rule.
    .DESCRIPTION
    Composes a replaceable reader with Get-ParVolumeAssessment. The default is
    synthetic; this command never selects a live source implicitly. Reader errors
    propagate to the caller rather than becoming a misleading empty report.
    .PARAMETER ReadVolume
    Script block called once with no arguments. Return objects matching the
    Get-ParVolumeAssessment input contract, or no objects for an empty report.
    The default calls Get-ParDemoVolume. Keep diagnostics off the success stream.
    Readers should use terminating errors when retrieval fails.
    .PARAMETER MinimumFreePercent
    Lowest acceptable free-space percentage. Defaults to 20 here, shared by both
    the automation script and API endpoint. Equality is OK.
    .INPUTS
    None
    .OUTPUTS
    PSCustomObject with Name, FreePercent, and Status; no output for no volumes.
    .EXAMPLE
    Get-ParVolumeReport
    Assesses the three synthetic volumes with the default threshold.
    .EXAMPLE
    Get-ParVolumeReport -ReadVolume {
        [pscustomobject]@{ Name = 'Alternate'; CapacityGB = 80; FreeGB = 20 }
    } -MinimumFreePercent 30
    Supplies another reader without editing the reporting or assessment functions.
    #>
    [CmdletBinding()]
    param(
        [scriptblock] $ReadVolume = { Get-ParDemoVolume },

        [ValidateRange(0, 100)]
        [int] $MinimumFreePercent = 20
    )

    $volumes = @(& $ReadVolume)
    Get-ParVolumeAssessment -Volume $volumes -MinimumFreePercent $MinimumFreePercent
}

Export-ModuleMember -Function Get-ParDemoVolume, Get-ParVolumeAssessment, Get-ParVolumeReport
