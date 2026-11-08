# Experimental only; not reference material for creating production PSU resources.
# Owner authorized .NET hashing, generic collections, and measurement in this benchmark.
[CmdletBinding()]
param([Parameter(Mandatory)][string] $RequestJson)

$ErrorActionPreference = 'Stop'
$request = $RequestJson | ConvertFrom-Json -AsHashtable
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$result = [ordered]@{ Id = $request.Id; Kind = $request.Kind; Pid = $PID; PowerShell = "$($PSVersionTable.PSVersion)" }
switch ($request.Kind) {
    'info' {
        $result.Executable = (Get-Process -Id $PID).Path
        $result.DotNet = [System.Environment]::Version.ToString()
        $result.Module = @(Get-Module Universal | Select-Object Name,Version,Path)
        $result.Command = Get-Command Set-PSUCache | Select-Object Name,ModuleName,Source
        $result.Variables = @(Get-Variable | Where-Object Name -Match 'PSU|Token|Universal' | Select-Object -ExpandProperty Name)
    }
    'cache-read' {
        foreach ($key in $request.Keys) { if ($key -notlike 'par-bench:*') { throw 'Invalid benchmark key' } }
        $read = @(foreach ($key in $request.Keys) { Get-PSUCache -Key $key -Integrated })
        $json = ConvertTo-Json -InputObject $read -Depth 30 -Compress
        $result.Records = $read.Count
        $result.Digest = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($json)))
    }
    'hash' {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes('PAR deterministic SHA-256 input|' * 128)
        $result.PrepareMs = $timer.Elapsed.TotalMilliseconds
        $timer.Restart()
        for ($i = 0; $i -lt $request.Iterations; $i++) {
            $digest = [System.Security.Cryptography.SHA256]::HashData($bytes)
        }
        $result.ComputeMs = $timer.Elapsed.TotalMilliseconds
        $result.Digest = if ($request.Iterations) { [Convert]::ToHexString($digest) } else { '' }
        $result.Iterations = $request.Iterations
        $result.InputBytes = $bytes.Length
    }
    'cache' {
        $records = @(for ($i = 0; $i -lt $request.Count; $i++) {
            $record = [ordered]@{ Id = $i }
            for ($p = 0; $p -lt $request.Properties; $p++) {
                $value = "r$i-p$p|" + ('x' * $request.Size)
                for ($d = 0; $d -lt $request.Nesting; $d++) { $value = [pscustomobject]@{ Child = $value } }
                $record["P$p"] = $value
            }
            [pscustomobject]$record
        })
        $partitions = @(for ($offset = 0; $offset -lt $records.Count; $offset += $request.PartSize) {
            ,@($records[$offset..([Math]::Min($offset + $request.PartSize, $records.Count) - 1)])
        })
        $expected = ConvertTo-Json -InputObject $records -Depth 30 -Compress
        $keys = @(for ($i = 0; $i -lt $partitions.Count; $i++) { "par-bench:$($request.Id):$i" })
        $result.PrepareMs = $timer.Elapsed.TotalMilliseconds
        $timer.Restart()
        for ($i = 0; $i -lt $keys.Count; $i++) {
            Set-PSUCache -Key $keys[$i] -Value $partitions[$i] -Persist -Depth 20 -AbsoluteExpirationFromNow (New-TimeSpan -Hours 2) -Integrated
        }
        $result.SetMs = $timer.Elapsed.TotalMilliseconds
        $timer.Restart()
        $read = @(foreach ($key in $keys) { Get-PSUCache -Key $key -Integrated })
        $result.GetAllMs = $timer.Elapsed.TotalMilliseconds
        if ((ConvertTo-Json -InputObject $read -Depth 30 -Compress) -cne $expected) { throw 'Cache round-trip differs' }
        $timer.Restart()
        $subset = @(Get-PSUCache -Key $keys[0] -Integrated)
        $result.GetOneMs = $timer.Elapsed.TotalMilliseconds
        if ($subset.Count -ne $partitions[0].Count) { throw 'Partition count differs' }
        $result.JsonBytes = [System.Text.Encoding]::UTF8.GetByteCount($expected)
        $result.Records = $records.Count
        $result.Partitions = $keys.Count
        $result.SubsetRecords = $subset.Count
        $result.Keys = $keys
    }
    'collections' {
        $count = [int]$request.Count
        $variant = $request.Variant
        $workloads = & "$PSScriptRoot/Get-CollectionWorkload.ps1"
        if ($variant -like '*-difference') {
            $left = [int[]]@(0..($count - 1))
            $right = [int[]]@(for ($i = 0; $i -lt $count; $i += 2) { $i })
        }
        $allocated = [GC]::GetAllocatedBytesForCurrentThread()
        $timer.Restart()
        $outcome = if ($variant -like '*-difference') { & $workloads[$variant] -Count $count -Left $left -Right $right } else { & $workloads[$variant] -Count $count }
        $result.ComputeMs = $timer.Elapsed.TotalMilliseconds
        $result.AllocatedBytes = [GC]::GetAllocatedBytesForCurrentThread() - $allocated
        $items = $outcome.Items
        $hits = $outcome.Hits
        $expectedCount = if ($variant -like '*-difference') { $count / 2 } else { $count }
        if ($items.Count -ne $expectedCount) { throw 'Collection count differs' }
        if ($variant -like '*-difference') {
            $expected = @(for ($i = 1; $i -lt $count; $i += 2) { $i })
            if (Compare-Object -ReferenceObject $expected -DifferenceObject @($items)) { throw 'Set difference differs' }
            $result.Checksum = ($items | Measure-Object -Sum).Sum
        } elseif ($variant -like '*membership') {
            if ($hits -ne $count) { throw 'Membership differs' }
            $result.Checksum = $hits
        } else {
            $values = if ($variant -in 'hashtable','dictionary') { $items.Values } else { $items }
            $sum = ($values | Measure-Object -Sum).Sum
            if ($sum -ne ($count * ($count - 1) / 2)) { throw 'Collection checksum differs' }
            if ($variant -in 'hashtable','dictionary' -and $items['KEY1'] -ne 1) { throw 'Key comparison differs' }
            $result.Checksum = $sum
        }
        $result.Variant = $variant
        $result.Count = $count
    }
    'noop' { $result.ComputeMs = 0 }
    'serialization' {
        $control = & "$PSScriptRoot/Measure-Serialization.ps1" -Count $request.Count -Size $request.Size
        foreach ($key in $control.Keys) { $result[$key] = $control[$key] }
    }
    default { throw "Unknown workload $($request.Kind)" }
}
[pscustomobject]$result
