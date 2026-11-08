# Experimental only; not reference material for creating production PSU resources.
[CmdletBinding()]
param([Parameter(Mandatory)][string] $RequestJson)

$ErrorActionPreference = 'Stop'
$request = $RequestJson | ConvertFrom-Json
if ($request.Id -notmatch '^[a-zA-Z0-9-]+$') { throw 'Invalid request ID' }
if ($request.Kind -eq 'output') {
    # Owner authorized .NET measurement in this benchmark. Input is prepared before timing.
    $values = @(for ($i = 0; $i -lt $request.Count; $i++) { "item-$i|" + ('x' * $request.Size) })
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    if ($request.Variant -eq 'suppress') { foreach ($value in $values) { $null = $value } }
    else { foreach ($value in $values) { $value } }
    $result = @{ Id = $request.Id; Kind = 'output'; EmitMs = $timer.Elapsed.TotalMilliseconds; Count = $values.Count; Characters = ($values | Measure-Object -Property Length -Sum).Sum; Pid = $PID; PowerShell = "$($PSVersionTable.PSVersion)" }
} else {
    $result = & "$PSScriptRoot/Invoke-Workload.ps1" -RequestJson $RequestJson
}
$result | ConvertTo-Json -Depth 30 -Compress | Set-Content "C:/dev-psu/bench-results/$($request.Id).json"
if ($request.Kind -ne 'output') { $result | ConvertTo-Json -Depth 30 -Compress }
