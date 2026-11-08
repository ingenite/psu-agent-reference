# Experimental only; not reference material for creating production PSU resources.
<#
.SYNOPSIS
Exports absolute timings and paired savings for the admin scenario passes.
.PARAMETER Pass
One or more retained pass names. Warm-up blocks are excluded.
.NOTES
Positive savings mean the alternative was faster than the named baseline.
Win counts are descriptive observations, not confidence probabilities or guarantees.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string[]] $Pass)
$ErrorActionPreference='Stop'
$root=Join-Path $PSScriptRoot '../output/benchmarks'
function Get-ScenarioDistribution {
    param([double[]] $Values)
    $sorted=@($Values|Sort-Object)
    $middle=[int][Math]::Floor($sorted.Count/2)
    $median=if($sorted.Count%2){$sorted[$middle]}else{($sorted[$middle-1]+$sorted[$middle])/2}
    [pscustomobject]@{Median=$median;Min=$sorted[0];Max=$sorted[-1];N=$sorted.Count}
}
$samples=@(foreach($name in $Pass){Get-Content "$root/$name/samples.jsonl"|ConvertFrom-Json|Where-Object{!$_.Warmup}})
$summary=@(foreach($group in ($samples|Group-Object {$_.Request.Label})){
    $first=$group.Group[0]
    $baseline=if($first.Request.Family -in 'cache','serialize'){'late'}elseif($first.Request.Family -eq 'report'){'report-array-add'}else{'lookup-foreach'}
    foreach($variant in ($first.Result.Variants.Name|Sort-Object)){
        $pairs=@(foreach($sample in $group.Group){
            $base=$sample.Result.Variants|Where-Object Name -EQ $baseline
            $other=$sample.Result.Variants|Where-Object Name -EQ $variant
            [pscustomobject]@{Total=$other.TotalMs;Savings=($base.TotalMs-$other.TotalMs);Data=$other}
        })
        $times=Get-ScenarioDistribution $pairs.Total
        $savings=Get-ScenarioDistribution $pairs.Savings
        $row=[ordered]@{
            Case=$group.Name;Family=$first.Request.Family;Source=$first.Request.Source;Count=$first.Request.Count
            Reads=$first.Request.Reads;Queries=$first.Request.Queries;Variant=$variant;Baseline=$baseline
            N=$times.N;MedianMs=$times.Median;MinMs=$times.Min;MaxMs=$times.Max
            MedianSavingsMs=$savings.Median;MinSavingsMs=$savings.Min;MaxSavingsMs=$savings.Max
            FasterPairs=@($pairs|Where-Object Savings -GT 0).Count
        }
        if($first.Request.Family -eq 'cache'){
            $row.StorageBytes=(Get-ScenarioDistribution $pairs.Data.StorageBytes).Median
            $row.ProjectionMedianMs=(Get-ScenarioDistribution $pairs.Data.ProjectionMs).Median
            $row.SetMedianMs=(Get-ScenarioDistribution $pairs.Data.SetMs).Median
            $row.PerReadMedianMs=(Get-ScenarioDistribution @($pairs.Data.Reads.TotalMs)).Median
            $row.UsefulCount=$pairs.Data.UsefulCount[0]
        }elseif($first.Request.Family -eq 'serialize'){
            $row.XmlBytes=(Get-ScenarioDistribution $pairs.Data.XmlBytes).Median
            $row.ProjectionMedianMs=(Get-ScenarioDistribution $pairs.Data.ProjectionMs).Median
            $row.SerializeMedianMs=(Get-ScenarioDistribution $pairs.Data.SerializeMs).Median
        }else{
            $row.AllocatedBytes=(Get-ScenarioDistribution $pairs.Data.AllocatedBytes).Median
        }
        [pscustomobject]$row
    }
})
$destination="$root/$($Pass[0])"
$summary|ConvertTo-Json -Depth 10|Set-Content "$destination/admin-summary.json"
$columns=@($summary|ForEach-Object{$_.PSObject.Properties.Name}|Select-Object -Unique)
$summary|Select-Object -Property $columns|Export-Csv "$destination/admin-summary.csv" -NoTypeInformation
$summary|Select-Object Case,Variant,MedianMs,MedianSavingsMs,FasterPairs,N|Format-Table -AutoSize
