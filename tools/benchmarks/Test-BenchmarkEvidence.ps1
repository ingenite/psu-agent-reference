# Experimental only; not reference material for creating production PSU resources.
<#
.SYNOPSIS
Verifies retained hash results and the exact synthetic strings stored for output jobs.
.PARAMETER Pass
The baseline pass containing samples.jsonl and storage.json.
.NOTES
Read-only database access; run before job history grooming. Assertions are experiment checks,
not unit tests or evidence about external systems.
#>
[CmdletBinding()]
param([string] $Pass = 'pass2')
$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '../output/benchmarks'
$inputFile = "$root/hash-input.txt"
Set-Content $inputFile -Value ('PAR deterministic SHA-256 input|' * 128) -NoNewline -Encoding utf8
$expectedDigest = (Get-FileHash $inputFile -Algorithm SHA256).Hash
$hashSamples = 0
foreach ($file in (Get-ChildItem $root -Filter '*.jsonl' -Recurse | Where-Object { $_.Directory.Name -ne 'source' })) {
    foreach ($sample in (Get-Content $file.FullName | ConvertFrom-Json)) {
        $results = if ($sample.Results) { $sample.Results } else { $sample.Result }
        foreach ($result in $results) {
            if ($result.Kind -eq 'hash' -and $result.Iterations -gt 0) {
                if ($result.Digest -cne $expectedDigest) { throw "Digest differs: $($result.Id)" }
                if ($result.InputBytes -ne 4096) { throw 'Hash input size differs' }
                $hashSamples++
            }
        }
    }
}
# Owner authorized .NET serialization and storage measurement in this benchmark.
Add-Type -Path C:/dev-psu/System.Data.SQLite.dll
$connection = [System.Data.SQLite.SQLiteConnection]::new('Data Source=C:\dev-psu\database\psu.db;Read Only=True;')
$connection.Open()
$outputJobs = 0
try {
    foreach ($sample in (Get-Content "$root/$Pass/samples.jsonl" | ConvertFrom-Json | Where-Object { $_.Request.Kind -eq 'output' })) {
        $request = $sample.Request
        $expected = @(for ($i = 0; $i -lt $request.Count; $i++) { "item-$i|" + ('x' * $request.Size) })
        if ($sample.Result.Characters -ne ($expected | Measure-Object -Property Length -Sum).Sum) { throw 'Output preparation differs' }
        $command = $connection.CreateCommand()
        $command.CommandText = 'SELECT Data FROM JobPipelineOutput WHERE JobId=@id'
        $null = $command.Parameters.AddWithValue('@id',[long]$sample.JobId)
        $xml = $command.ExecuteScalar()
        if ($request.Variant -eq 'emit') {
            $stored = [System.Management.Automation.PSSerializer]::Deserialize($xml)
            if ($stored.Count -ne $expected.Count) { throw 'Stored pipeline count differs' }
            for ($i = 0; $i -lt $expected.Count; $i++) { if ($stored[$i] -cne $expected[$i]) { throw 'Stored pipeline value differs' } }
        } elseif ($null -ne $xml) { throw 'Unexpected saved pipeline output' }
        $command.CommandText = 'SELECT Message FROM JobOutput WHERE JobId=@id ORDER BY Id'
        $reader = $command.ExecuteReader()
        $index = 0
        while ($reader.Read()) {
            if ($request.Variant -eq 'suppress' -or $reader.GetString(0) -cne $expected[$index]) { throw 'Job log value differs' }
            $index++
        }
        $reader.Close()
        if ($request.Variant -ne 'suppress' -and $index -ne $expected.Count) { throw 'Job log count differs' }
        $command.Dispose()
        $outputJobs++
    }
} finally { $connection.Dispose() }
$dashboardHashes = 0
foreach ($file in (Get-ChildItem $root -Directory -Filter 'dashboard-*' | Get-ChildItem -Filter 'dashboard-*.json' -File)) {
    $row = Get-Content $file.FullName -Raw | ConvertFrom-Json
    if ($row.Result.Iterations -gt 0) {
        if ($row.Result.Digest -cne $expectedDigest) { throw 'Dashboard digest differs' }
        $dashboardHashes++
    }
}
@{HashSamples=$hashSamples;DashboardHashSamples=$dashboardHashes;OutputJobs=$outputJobs;Digest=$expectedDigest;Utc=(Get-Date).ToUniversalTime().ToString('o')} | ConvertTo-Json | Set-Content "$root/equivalence.json"
Write-Output "Equivalent results verified: $root/equivalence.json"
