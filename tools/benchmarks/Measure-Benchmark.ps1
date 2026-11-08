# Experimental only; not reference material for creating production PSU resources.
<#
.SYNOPSIS
Summarizes retained samples with medians and observed ranges, excluding explicit warm-up blocks.
.PARAMETER Pass
Existing pass directory under tools/output/benchmarks.
.NOTES
Request timings within a concurrent burst are correlated. BatchWallMs and
DriverCycleRequestsPerSecond use one observation per burst, including driver
dispatch and job evidence collection after completion has been observed.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string] $Pass)
$ErrorActionPreference = 'Stop'
$output = Join-Path $PSScriptRoot "../output/benchmarks/$Pass"
function Get-Distribution {
    param([double[]] $Values)
    $sorted = @($Values | Sort-Object)
    $middle = [int][Math]::Floor($sorted.Count / 2)
    $median = if ($sorted.Count % 2) { $sorted[$middle] } else { ($sorted[$middle - 1] + $sorted[$middle]) / 2 }
    [ordered]@{ N=$sorted.Count; Median=$median; Min=$sorted[0]; Max=$sorted[-1] }
}
$rows = @(foreach ($file in 'samples.jsonl','load.jsonl') {
    if (Test-Path "$output/$file") { Get-Content "$output/$file" | ConvertFrom-Json | Where-Object { !$_.Warmup } }
})
$summary = foreach ($group in ($rows | Group-Object { "$($_.Request.Label)|$($_.Location)|$($_.Request.Concurrency)" })) {
    $entry = [ordered]@{ Case=$group.Name; RequestCount=$group.Count }
    foreach ($metric in 'EndToEndMs','ServerDurationMs','ServerQueueMs','AcceptanceMs','PipelineFetchMs','PipelineHttpBytes') {
        $values = @($group.Group | Where-Object { $null -ne $_.$metric } | ForEach-Object { $_.$metric })
        if ($values.Count) { $entry[$metric] = Get-Distribution $values }
    }
    $bursts = @($group.Group | Where-Object { $null -ne $_.BatchWallMs } | Group-Object Block)
    if ($bursts.Count) {
        $entry.BurstCount = $bursts.Count
        $wallTimes = @()
        $rates = @()
        foreach ($burst in $bursts) {
            # Older passes read the same running clock while saving each row.
            $wallMs = ($burst.Group | Measure-Object BatchWallMs -Maximum).Maximum
            $wallTimes += $wallMs
            $rates += $burst.Count * 1000 / $wallMs
        }
        $entry.BatchWallMs = Get-Distribution $wallTimes
        $entry.DriverCycleRequestsPerSecond = Get-Distribution $rates
    }
    foreach ($metric in 'ComputeMs','PrepareMs','SetMs','GetAllMs','GetOneMs','AllocatedBytes','EmitMs','SerializeMs','DeserializeMs') {
        $values = @($group.Group | ForEach-Object { $_.Result } | Where-Object { $null -ne $_.$metric } | ForEach-Object { $_.$metric })
        if ($values.Count) { $entry[$metric] = Get-Distribution $values }
    }
    [pscustomobject]$entry
}
$summary | ConvertTo-Json -Depth 20 | Set-Content "$output/summary.json"
$summary | Select-Object Case,@{n='ComputeMedianMs';e={$_.ComputeMs.Median}},@{n='EndToEndMedianMs';e={$_.EndToEndMs.Median}},@{n='SetMedianMs';e={$_.SetMs.Median}},@{n='GetAllMedianMs';e={$_.GetAllMs.Median}} | Format-Table -AutoSize
