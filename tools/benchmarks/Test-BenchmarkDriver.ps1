# Experimental only; not reference material for creating production PSU resources.
<#
.SYNOPSIS
Checks endpoint burst behavior with asynchronous HTTP instead of PowerShell parallel runspaces.
.NOTES
Runs no-op and hash bursts of one and four; retains warm-ups, driver CPU, and batch wall time.
#>
[CmdletBinding()]
param([string] $Pass = 'driver', [int] $Repetitions = 5)
$ErrorActionPreference = 'Stop'
$output = Join-Path $PSScriptRoot "../output/benchmarks/$Pass"
if (Test-Path $output) { throw 'Pass exists' }
New-Item $output -ItemType Directory -Force | Out-Null
# Owner authorized .NET HTTP and timing instrumentation for the benchmark.
$handler = [System.Net.Http.HttpClientHandler]::new()
$handler.AllowAutoRedirect = $false
$client = [System.Net.Http.HttpClient]::new($handler)
try {
    foreach ($block in 0..$Repetitions) {
        foreach ($kind in 'noop','hash') { foreach ($count in 1,4) {
            $process = Get-Process -Id $PID
            $cpu = $process.TotalProcessorTime.TotalMilliseconds
            $timer = [System.Diagnostics.Stopwatch]::StartNew()
            $tasks = @(for ($i = 0; $i -lt $count; $i++) {
                $body = @{Id="driver-$block-$kind-$count-$i";Kind=$kind;Iterations=100000} | ConvertTo-Json -Compress
                $content = [System.Net.Http.StringContent]::new($body,[System.Text.Encoding]::UTF8,'application/json')
                $client.PostAsync('http://127.0.0.1:5100/api/par-benchmark',$content)
            })
            [System.Threading.Tasks.Task]::WaitAll([System.Threading.Tasks.Task[]]$tasks)
            $wallMs = $timer.Elapsed.TotalMilliseconds
            $process.Refresh()
            $driverCpuMs = $process.TotalProcessorTime.TotalMilliseconds - $cpu
            $results = @(foreach ($task in $tasks) {
                $response = $task.Result
                $null = $response.EnsureSuccessStatusCode()
                $response.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
                $response.Dispose()
            })
            @{Block=$block;Warmup=($block -eq 0);Kind=$kind;Concurrency=$count;BatchWallMs=$wallMs;DriverCpuMs=$driverCpuMs;Results=$results} | ConvertTo-Json -Depth 15 -Compress | Add-Content "$output/samples.jsonl"
        } }
    }
} finally { $client.Dispose() }
Write-Output "Driver control measurements: $output"
