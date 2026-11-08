# Experimental only; not reference material for creating production PSU resources.
<#
.SYNOPSIS
Runs a bounded, seeded benchmark pass against the dedicated C:\dev-psu instance.
.PARAMETER Pass
Names an output directory below tools/output/benchmarks. Existing passes are never overwritten.
.PARAMETER Repetitions
Number of measured blocks after one separate warm-up block.
.PARAMETER Group
Selects initial experiments or a focused rerun.
.NOTES
Install preview with Set-BenchmarkPreview.ps1 first. Raw JSONL is flushed after each sample.
One seeded random order per block; concurrency uses separate PowerShell runspaces.
#>
[CmdletBinding()]
param(
    [ValidatePattern('^[a-zA-Z0-9-]+$')][string] $Pass = 'first',
    [ValidateRange(1,30)][int] $Repetitions = 7,
    [ValidateSet('all','hash','cache','output','collections','load','serialization','difference')][string] $Group = 'all',
    [int] $Seed = 731,
    [ValidateRange(1000,1000000)][int] $LoadIterations = 100000
)
$ErrorActionPreference = 'Stop'
$output = Join-Path $PSScriptRoot "../output/benchmarks/$Pass"
if (Test-Path $output) { throw "Pass already exists: $Pass" }
New-Item $output -ItemType Directory -Force | Out-Null
New-Item "$output/source" -ItemType Directory -Force | Out-Null
Copy-Item "$PSScriptRoot/*.ps1" "$output/source"
$token = Get-Secret -Name dev-psu-codex-mgmt-api -AsPlainText
$headers = @{ Authorization = "Bearer $token" }
$scripts = Invoke-RestMethod http://127.0.0.1:5100/api/v1/script -Headers $headers -MaximumRedirection 0
$jobId = ($scripts | Where-Object name -eq 'Invoke-BenchmarkJob.ps1').id
$discardId = ($scripts | Where-Object name -eq 'Invoke-BenchmarkDiscard.ps1').id
if (!$jobId -or !$discardId) { throw 'Benchmark scripts are not registered' }
$metadata = @{
    Utc = (Get-Date).ToUniversalTime().ToString('o'); Pass = $Pass; Repetitions = $Repetitions; Seed = $Seed
    HarnessPowerShell = "$($PSVersionTable.PSVersion)"; OS = $PSVersionTable.OS
    Commit = (git rev-parse HEAD); Group = $Group; LoadIterations = $LoadIterations
    Version = Invoke-RestMethod http://127.0.0.1:5100/api/v1/version -Headers $headers -MaximumRedirection 0
    Environments = Invoke-RestMethod http://127.0.0.1:5100/api/v1/environment -Headers $headers -MaximumRedirection 0
    SourceHashes = @(Get-ChildItem $PSScriptRoot -File | Get-FileHash | Select-Object Path,Hash)
    Processor = @(Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors)
    Computer = Get-CimInstance Win32_ComputerSystem | Select-Object TotalPhysicalMemory
}
$metadata | ConvertTo-Json -Depth 30 | Set-Content "$output/metadata.json"
$cases = @(
    if ($Group -in 'all','difference') {
        foreach ($count in 100,10000) { foreach ($variant in 'hashtable-difference','hashset-difference') {
            @{ Kind='collections'; Location='endpoint'; Count=$count; Variant=$variant; Label="collections-$variant-$count" }
        } }
    }
    if ($Group -in 'all','serialization') {
        foreach ($count in 100,5000) {
            @{ Kind='serialization'; Location='endpoint'; Count=$count; Size=128; Label="serialization-$count" }
        }
    }
    if ($Group -in 'all','hash') {
        foreach ($location in 'endpoint','job') { foreach ($iterations in 0,10000,100000) {
            @{ Kind = 'hash'; Location = $location; Iterations = $iterations; Label = "hash-$iterations" }
        } }
    }
    if ($Group -in 'all','cache') {
        foreach ($shape in @(
            @(100,4,0,32,100), @(1000,4,0,32,1000), @(1000,16,0,32,1000),
            @(1000,4,2,32,1000), @(1000,4,0,1024,1000), @(1000,4,0,32,100), @(1000,4,0,1024,100)
        )) {
            @{ Kind='cache'; Location='endpoint'; Count=$shape[0]; Properties=$shape[1]; Nesting=$shape[2]; Size=$shape[3]; PartSize=$shape[4]; Label="cache-$($shape -join '-')" }
        }
    }
    if ($Group -in 'all','output') {
        foreach ($variant in 'emit','suppress','discard') { foreach ($count in 100,5000) {
            @{ Kind='output'; Location=$(if ($variant -eq 'discard') { 'discard' } else { 'job' }); Count=$count; Size=128; Variant=$variant; Label="output-$variant-$count" }
        } }
    }
    if ($Group -in 'all','collections') {
        foreach ($count in 100,10000) { foreach ($variant in 'array-add','array-capture','list','hashtable','dictionary','array-membership','hashtable-membership','hashset-membership') {
            @{ Kind='collections'; Location='endpoint'; Count=$count; Variant=$variant; Label="collections-$variant-$count" }
        } }
    }
)
$cases | ConvertTo-Json -Depth 10 | Set-Content "$output/plan.json"
Get-Random -SetSeed $Seed | Out-Null
foreach ($block in 0..$Repetitions) {
    foreach ($case in ($cases | Get-Random -Shuffle)) {
        $request = $case.Clone()
        $request.Id = "$Pass-b$block-$($case.Label)-$($case.Location)"
        $sample = & "$PSScriptRoot/Invoke-Sample.ps1" -RequestJson ($request | ConvertTo-Json -Compress) -Location $case.Location -Headers $headers -ScriptId $(if ($case.Location -eq 'discard') { $discardId } else { $jobId })
        $sample.Block = $block
        $sample.Warmup = $block -eq 0
        $sample | ConvertTo-Json -Depth 30 -Compress | Add-Content "$output/samples.jsonl"
    }
    Write-Output "Completed $Pass block $block / $Repetitions"
}
if ($Group -in 'all','load') {
    $samplePath = "$PSScriptRoot/Invoke-Sample.ps1"
    foreach ($block in 0..$Repetitions) {
        foreach ($location in ('endpoint','job' | Get-Random -Shuffle)) {
            foreach ($concurrency in (1,4 | Get-Random -Shuffle)) {
                # Owner authorized .NET measurement; includes dispatch and post-completion job evidence collection.
                $timer = [System.Diagnostics.Stopwatch]::StartNew()
                $samples = 1..$concurrency | ForEach-Object -Parallel {
                    $request = @{Id="$using:Pass-load-$using:block-$using:location-$using:concurrency-$_"; Kind='hash'; Iterations=$using:LoadIterations; Label="hash-$using:LoadIterations"; Concurrency=$using:concurrency}
                    & $using:samplePath -RequestJson ($request | ConvertTo-Json -Compress) -Location $using:location -Headers $using:headers -ScriptId $using:jobId
                } -ThrottleLimit $concurrency
                $batchWallMs = $timer.Elapsed.TotalMilliseconds
                foreach ($sample in $samples) {
                    $sample.Block=$block; $sample.Warmup=$block -eq 0; $sample.BatchWallMs=$batchWallMs
                    $sample | ConvertTo-Json -Depth 30 -Compress | Add-Content "$output/load.jsonl"
                }
            }
        }
    }
}
Write-Output "Raw measurements: $output"
