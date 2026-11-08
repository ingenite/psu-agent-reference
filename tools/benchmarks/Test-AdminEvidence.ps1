# Experimental only; not reference material for creating production PSU resources.
<#
.SYNOPSIS
Checks that retained admin passes are complete and their timer/size contracts agree.
.NOTES
Does not require an active PSU endpoint. Full result equality was asserted inside
each scenario before it returned; live process values are intentionally not retained.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][string[]] $Pass)
$ErrorActionPreference='Stop'
$root=Join-Path $PSScriptRoot '../output/benchmarks'
$checked=@(foreach($name in $Pass){
    if($name -notmatch '^[a-zA-Z0-9-]+$'){throw 'Invalid pass name'}
    $metadata=Get-Content "$root/$name/metadata.json" -Raw|ConvertFrom-Json
    $plan=@(Get-Content "$root/$name/plan.json" -Raw|ConvertFrom-Json)
    $samples=@(Get-Content "$root/$name/samples.jsonl"|ConvertFrom-Json)
    if($samples.Count -ne ($plan.Count*($metadata.Repetitions+1))){throw "Incomplete pass: $name"}
    foreach($block in 0..$metadata.Repetitions){
        $rows=@($samples|Where-Object Block -EQ $block)
        if($rows.Count -ne $plan.Count -or @($rows.Request.Label|Select-Object -Unique).Count -ne $plan.Count){throw 'Block cases differ'}
    }
    foreach($sample in $samples){
        $request=$sample.Request
        $result=$sample.Result
        if($result.Count -ne $request.Count -or $result.Variants.Count -ne $request.Order.Count){throw 'Scenario count differs'}
        if(Compare-Object -ReferenceObject @($request.Order) -DifferenceObject @($result.Variants.Name)){throw 'Variants differ'}
        if($sample.Warmup -ne ($sample.Block -eq 0)){throw 'Warm-up classification differs'}
        foreach($variant in $result.Variants){
            if($variant.TotalMs -lt 0){throw 'Negative duration'}
            if($request.Family -eq 'cache'){
                if($variant.Reads.Count -ne $request.Reads -or $variant.StorageBytes -le 0){throw 'Cache measurements missing'}
                $sum=$variant.ProjectionMs+$variant.SetMs+($variant.Reads|Measure-Object -Property TotalMs -Sum).Sum
                # Owner authorized .NET numerical measurement within this benchmark.
                if([Math]::Abs($sum-$variant.TotalMs) -gt 0.000001){throw 'Cache timer sum differs'}
                $expectedStored=if($variant.Name -eq 'early'){$result.UsefulCount}else{$request.Count}
                if($variant.StoredCount -ne $expectedStored){throw 'Stored row count differs'}
            }elseif($request.Family -eq 'lookup'){
                if($variant.UsefulCount -ne $request.Queries){throw 'Lookup count differs'}
            }elseif($variant.UsefulCount -ne $request.Count){throw 'Report/control count differs'}
        }
    }
    @{Pass=$name;Cases=$plan.Count;Samples=$samples.Count;MeasuredSamples=@($samples|Where-Object{!$_.Warmup}).Count;Variants=($samples.Result.Variants|Measure-Object).Count}
})
$checked|ConvertTo-Json -Depth 5|Set-Content "$root/$($Pass[0])/evidence-check.json"
$checked|Format-Table -AutoSize
