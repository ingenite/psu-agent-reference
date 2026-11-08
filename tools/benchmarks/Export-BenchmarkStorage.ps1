# Experimental only; not reference material for creating production PSU resources.
<#
.SYNOPSIS
Exports logical SQLite payload sizes for benchmark rows only, without modifying the database.
.PARAMETER Pass
Existing tools/output/benchmarks pass directory name. Run before cache entries expire.
.NOTES
Uses the SQLite provider shipped with the dedicated instance. Byte totals exclude indexes,
page allocation, journal/WAL space, and filesystem compression. Never uses whole-database growth as per-job storage.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9-]+$')][string] $Pass)
$ErrorActionPreference = 'Stop'
# Owner authorized .NET measurement in this benchmark; all SQL connections are read-only.
Add-Type -Path C:/dev-psu/System.Data.SQLite.dll
$connection = [System.Data.SQLite.SQLiteConnection]::new('Data Source=C:\dev-psu\database\psu.db;Read Only=True;')
$connection.Open()
try {
    $output = Join-Path $PSScriptRoot "../output/benchmarks/$Pass"
    $samples = @(Get-Content "$output/samples.jsonl" | ConvertFrom-Json)
    $rows = foreach ($sample in $samples) {
        $command = $connection.CreateCommand()
        if ($sample.Request.Kind -eq 'cache') {
            $command.CommandText = "SELECT count(*) AS Rows, coalesce(sum(length(CAST(Value AS BLOB))),0) AS Bytes, min(Persistent) AS FlagMin, max(Persistent) AS FlagMax FROM Dataitems WHERE Key LIKE @prefix"
            $null = $command.Parameters.AddWithValue('@prefix', "par-bench:$($sample.Request.Id):%")
            $reader = $command.ExecuteReader()
            $null = $reader.Read()
            [pscustomobject]@{ Id=$sample.Request.Id; Category='cache'; Rows=[long]$reader['Rows']; ValueBytes=[long]$reader['Bytes']; PersistentFlagMin=$reader['FlagMin']; PersistentFlagMax=$reader['FlagMax'] }
            $reader.Close()
        } elseif ($sample.JobId) {
            $command.CommandText = 'SELECT count(*) AS Rows, coalesce(sum(length(CAST(Data AS BLOB))),0) AS DataBytes, coalesce(sum(length(CAST(JsonData AS BLOB))),0) AS JsonBytes, count(FileId) AS Files FROM JobPipelineOutput WHERE JobId = @id'
            $null = $command.Parameters.AddWithValue('@id', [long]$sample.JobId)
            $reader = $command.ExecuteReader(); $null = $reader.Read()
            $row = [ordered]@{ Id=$sample.Request.Id; Category='job'; JobId=$sample.JobId; PipelineRows=[long]$reader['Rows']; PipelineDataBytes=[long]$reader['DataBytes']; PipelineJsonBytes=[long]$reader['JsonBytes']; Files=[long]$reader['Files'] }
            $reader.Close()
            $command.CommandText = 'SELECT count(*) AS Rows, coalesce(sum(length(CAST(Message AS BLOB))),0) AS MessageBytes, coalesce(sum(length(CAST(Data AS BLOB))),0) AS DataBytes FROM JobOutput WHERE JobId = @id'
            $reader = $command.ExecuteReader(); $null = $reader.Read()
            $row.LogRows=[long]$reader['Rows']; $row.LogMessageBytes=[long]$reader['MessageBytes']; $row.LogDataBytes=[long]$reader['DataBytes']
            $reader.Close()
            [pscustomobject]$row
        }
        $command.Dispose()
    }
    $rows | ConvertTo-Json -Depth 10 | Set-Content "$output/storage.json"
    Write-Output "Logical benchmark payload sizes: $output/storage.json"
} finally { $connection.Dispose() }
