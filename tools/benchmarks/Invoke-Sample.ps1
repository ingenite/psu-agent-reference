# Experimental only; not reference material for creating production PSU resources.
# Owner authorized .NET timing and HTTP instrumentation for this benchmark.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $RequestJson,
    [ValidateSet('endpoint','job','discard')][string] $Location = 'endpoint',
    [hashtable] $Headers,
    [int] $ScriptId,
    [int] $PollMilliseconds = 50
)
$ErrorActionPreference = 'Stop'
$request = $RequestJson | ConvertFrom-Json
$timer = [System.Diagnostics.Stopwatch]::StartNew()
if ($Location -eq 'endpoint') {
    $uri = if ($request.Kind -eq 'cache') { 'http://127.0.0.1:5100/api/par-benchmark-cache' } else { 'http://127.0.0.1:5100/api/par-benchmark' }
    $result = @(Invoke-RestMethod $uri -Headers $Headers -Method Post -Body $RequestJson -ContentType application/json -MaximumRedirection 0)[0]
    $elapsed = $timer.Elapsed.TotalMilliseconds
    $sample = @{ Request = $request; Location = $Location; EndToEndMs = $elapsed; Result = $result }
} else {
    $body = @{ jobParameters = @(@{ name = 'RequestJson'; type = 'System.String'; value = [System.Management.Automation.PSSerializer]::Serialize($RequestJson); stringValue = $RequestJson }) } | ConvertTo-Json -Depth 20 -Compress
    $timer.Restart()
    $acceptedId = Invoke-RestMethod "http://127.0.0.1:5100/api/v1/script/$ScriptId" -Method Post -Headers $Headers -Body $body -ContentType application/json -MaximumRedirection 0
    $job = @{ id = $acceptedId }
    $acceptMs = $timer.Elapsed.TotalMilliseconds
    $polls = 0
    do {
        if ($timer.Elapsed.TotalSeconds -gt 120) { throw "Job $($job.id) timed out in harness" }
        Start-Sleep -Milliseconds $PollMilliseconds
        $job = Invoke-RestMethod "http://127.0.0.1:5100/api/v1/job/$($job.id)" -Headers $Headers -MaximumRedirection 0
        $polls++
    } while ($job.status -in 0,1)
    $elapsed = $timer.Elapsed.TotalMilliseconds
    if ($job.status -ne 2) { throw "Job $($job.id) status $($job.status)" }
    $result = Get-Content "C:/dev-psu/bench-results/$($request.Id).json" -Raw | ConvertFrom-Json
    $timer.Restart()
    $pipeline = Invoke-WebRequest "http://127.0.0.1:5100/api/v1/job/$($job.id)/pipelineOutput" -Headers $Headers -MaximumRedirection 0
    $fetchMs = $timer.Elapsed.TotalMilliseconds
    $sample = @{
        Request = $request; Location = $Location; EndToEndMs = $elapsed; AcceptanceMs = $acceptMs
        Polls = $polls; PollMilliseconds = $PollMilliseconds; Result = $result; JobId = $job.id
        CreatedTime = $job.createdTime; StartTime = $job.startTime; EndTime = $job.endTime
        ServerDurationMs = ([datetime]$job.endTime - [datetime]$job.startTime).TotalMilliseconds
        ServerQueueMs = ([datetime]$job.startTime - [datetime]$job.createdTime).TotalMilliseconds
        PipelineFetchMs = $fetchMs; PipelineHttpBytes = $pipeline.RawContentLength
        PipelineItems = @($pipeline.Content | ConvertFrom-Json).Count
    }
}
$sample
