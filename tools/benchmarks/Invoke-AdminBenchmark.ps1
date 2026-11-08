# Experimental only; not reference material for creating production PSU resources.
<#
.SYNOPSIS
Measures paired admin scenarios to locate practical crossover ranges.
.PARAMETER Pass
New output directory name below tools/output/benchmarks.
.PARAMETER Group
Selects cache, report construction, or directory lookup scenarios.
.PARAMETER Repetitions
Measured blocks after one explicit warm-up block.
.NOTES
Install Set-BenchmarkPreview.ps1 first. Cache payloads are removed after their sizes
are read. Live process values are not exported. Directory records are synthetic.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9-]+$')][string] $Pass,
    [ValidateSet('all','cache','report','lookup','process-control')][string] $Group='all',
    [ValidateRange(1,15)][int] $Repetitions=7,
    [int[]] $DirectoryCounts=@(1,5,10,25,100,500,1000),
    [int[]] $ProcessCounts=@(1,10,50,100),
    [int[]] $ReportCounts=@(1,10,100,1000,5000,10000),
    [int[]] $LookupCounts=@(100,1000,5000),
    [int[]] $QueryCounts=@(1,5,20),
    [int] $Seed=1107
)
$ErrorActionPreference='Stop'
$output=Join-Path $PSScriptRoot "../output/benchmarks/$Pass"
if (Test-Path $output) { throw "Pass already exists: $Pass" }
New-Item "$output/source" -ItemType Directory -Force | Out-Null
Copy-Item "$PSScriptRoot/*.ps1" "$output/source"
$token=Get-Secret -Name dev-psu-codex-mgmt-api -AsPlainText
$headers=@{Authorization="Bearer $token"}
$schema=Invoke-RestMethod http://127.0.0.1:5100/swagger/v1/swagger.json -Headers $headers -MaximumRedirection 0
if (!$schema.paths) { throw 'Management schema unavailable' }
@{
    Utc=(Get-Date).ToUniversalTime().ToString('o');Seed=$Seed;Repetitions=$Repetitions;Group=$Group
    Version=Invoke-RestMethod http://127.0.0.1:5100/api/v1/version -Headers $headers -MaximumRedirection 0
    Environments=Invoke-RestMethod http://127.0.0.1:5100/api/v1/environment -Headers $headers -MaximumRedirection 0
    HarnessPowerShell="$($PSVersionTable.PSVersion)";OS=$PSVersionTable.OS
    SourceHashes=@(Get-ChildItem $PSScriptRoot -File | Get-FileHash | Select-Object Path,Hash)
    SourceCommit=(git rev-parse HEAD)
    Expectations=@('Projection trades one preparation pass for smaller cache writes/reads.',
        'Index comparisons include rebuilding the index for every measured workload.',
        'Reports construct the same new objects and return object arrays.',
        'Measured wins are local observations, not universal count thresholds.')
}|ConvertTo-Json -Depth 20|Set-Content "$output/metadata.json"
$cases=@(
    if ($Group -eq 'process-control') { foreach ($count in 1,10) {
        @{Family='serialize';Source='process';Count=$count;View='columns';Label="process-serialization-$count";Order=@('early','late')}
    } }
    if ($Group -in 'all','cache') {
        foreach ($count in $DirectoryCounts) { foreach ($view in 'columns','enabled-table') { foreach ($reads in 1,5) {
            @{Family='cache';Source='directory';Count=$count;View=$view;Reads=$reads;Label="directory-$view-$count-r$reads";Order=@('early','late')}
        } } }
        foreach ($count in $ProcessCounts) { foreach ($reads in 1,5) {
            @{Family='cache';Source='process';Count=$count;View='columns';Reads=$reads;Label="process-columns-$count-r$reads";Order=@('early','late')}
        } }
    }
    if ($Group -in 'all','report') { foreach ($count in $ReportCounts) {
        @{Family='report';Source='directory';Count=$count;Label="report-$count";Order=@('report-array-add','report-array-capture','report-list')}
    } }
    if ($Group -in 'all','lookup') { foreach ($count in $LookupCounts) { foreach ($queries in $QueryCounts) {
        @{Family='lookup';Source='directory';Count=$count;Queries=$queries;Label="lookup-$count-q$queries";Order=@('lookup-where','lookup-foreach','lookup-hashtable','lookup-dictionary')}
    } } }
)
$cases|ConvertTo-Json -Depth 10|Set-Content "$output/plan.json"
# Owner authorized .NET storage and timing instrumentation within the benchmark.
Add-Type -Path C:/dev-psu/System.Data.SQLite.dll
$connection=[System.Data.SQLite.SQLiteConnection]::new('Data Source=C:\dev-psu\database\psu.db;Read Only=True;')
$connection.Open()
Get-Random -SetSeed $Seed|Out-Null
try {
    foreach ($block in 0..$Repetitions) {
        foreach ($case in ($cases | Get-Random -Shuffle)) {
            $request=$case.Clone()
            $request.Id="$Pass-b$block-$($case.Label)"
            $request.Order=@($case.Order|Get-Random -Shuffle)
            $timer=[System.Diagnostics.Stopwatch]::StartNew()
            $response=Invoke-RestMethod http://127.0.0.1:5100/api/par-admin-benchmark -Method Post -Headers $headers -ContentType application/json -Body ($request|ConvertTo-Json -Depth 10 -Compress) -MaximumRedirection 0
            $httpMs=$timer.Elapsed.TotalMilliseconds
            $result=$response|Select-Object -First 1
            if ($result.Id -ne $request.Id -or $result.Count -ne $request.Count) { throw 'Unexpected scenario result' }
            if ($case.Family -eq 'cache') {
                foreach ($variant in $result.Variants) {
                    $command=$connection.CreateCommand()
                    $command.CommandText='SELECT length(CAST(Value AS BLOB)) FROM Dataitems WHERE Key=@key'
                    $null=$command.Parameters.AddWithValue('@key',$variant.Key)
                    $bytes=$command.ExecuteScalar()
                    $command.Dispose()
                    if (!$bytes) { throw 'Stored cache payload not found' }
                    $variant|Add-Member -NotePropertyName StorageBytes -NotePropertyValue ([long]$bytes)
                }
            }
            @{Request=$request;Result=$result;Block=$block;Warmup=($block -eq 0);HttpMs=$httpMs}|ConvertTo-Json -Depth 25 -Compress|Add-Content "$output/samples.jsonl"
            if ($case.Family -eq 'cache') {
                $keys=@($result.Variants.Key)
                Invoke-RestMethod http://127.0.0.1:5100/api/par-benchmark-cleanup -Method Post -Headers $headers -ContentType application/json -Body (@{Keys=$keys}|ConvertTo-Json -Compress) -MaximumRedirection 0|Out-Null
            }
        }
        Write-Output "Completed $Pass block $block / $Repetitions"
    }
} finally { $connection.Dispose() }
Write-Output "Admin scenario evidence: $output"
