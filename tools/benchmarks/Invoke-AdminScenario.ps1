# Experimental only; not reference material for creating production PSU resources.
# Owner authorized .NET timing, serialization and collection measurement in this benchmark.
[CmdletBinding()]
param([Parameter(Mandatory)][string] $RequestJson)
$ErrorActionPreference = 'Stop'
$request = $RequestJson | ConvertFrom-Json
if ($request.Id -notmatch '^[a-zA-Z0-9-]+$') { throw 'Invalid scenario ID' }
if ($request.Count -lt 1 -or $request.Count -gt 10000) { throw 'Count must be between 1 and 10000' }
$timer = [System.Diagnostics.Stopwatch]::StartNew()
if ($request.Source -eq 'process') {
    $sessionId = (Get-Process -Id $PID).SessionId
    $available = @(Get-Process | Where-Object SessionId -EQ $sessionId | Sort-Object Id)
    $source = @($available | Select-Object -First $request.Count)
    if ($source.Count -ne $request.Count) { throw "Only $($available.Count) process objects available in the server session" }
    $properties = 'Id','ProcessName','SessionId'
    $depth = 1
} elseif ($request.Source -eq 'directory') {
    $source = @(& "$PSScriptRoot/New-DirectoryFixture.ps1" -Count $request.Count)
    $properties = 'SamAccountName','DisplayName','Mail','Department'
    $depth = 3
} else { throw 'Unknown source' }
$prepareMs = $timer.Elapsed.TotalMilliseconds
$result = [ordered]@{
    Id=$request.Id; Source=$request.Source; Count=$source.Count; Family=$request.Family
    SourcePrepareMs=$prepareMs; SourceType=$source[0].GetType().FullName
    SourcePropertyCount=@($source[0].PSObject.Properties).Count
    PowerShell="$($PSVersionTable.PSVersion)"; Pid=$PID; Variants=@()
}
if ($request.Source -eq 'process') {
    $typeData = Get-TypeData -TypeName System.Diagnostics.Process
    $result.ScriptPropertyGetters = @(foreach ($name in 'Company','Description','FileVersion','Product','ProductVersion') {
        @{Name=$name;Getter=$typeData.Members[$name].GetScriptBlock.ToString()}
    })
}
if ($request.Family -in 'cache','serialize') {
    if ($request.Family -eq 'cache' -and ($request.Reads -lt 1 -or $request.Reads -gt 20)) { throw 'Reads must be between 1 and 20' }
    $expected = if ($request.View -eq 'enabled-table') {
        @($source | Where-Object Enabled -EQ $true | Select-Object -Property $properties)
    } else { @($source | Select-Object -Property $properties) }
    $expectedJson = ConvertTo-Json -InputObject @($expected) -Depth 10 -Compress
    foreach ($variant in $request.Order) {
        $key = "par-bench:$($request.Id):$variant"
        $projectionMs = 0
        if ($variant -eq 'early') {
            $timer.Restart()
            $payload = if ($request.View -eq 'enabled-table') { @($source | Where-Object Enabled -EQ $true | Select-Object -Property $properties) }
                else { @($source | Select-Object -Property $properties) }
            $projectionMs = $timer.Elapsed.TotalMilliseconds
        } else { $payload = $source }
        if ($request.Family -eq 'serialize') {
            $timer.Restart()
            $xml = [System.Management.Automation.PSSerializer]::Serialize(@($payload), $depth)
            $serializeMs = $timer.Elapsed.TotalMilliseconds
            $roundTrip = [System.Management.Automation.PSSerializer]::Deserialize($xml)
            $rows = @($roundTrip | Select-Object -Property $properties)
            if ((ConvertTo-Json -InputObject $rows -Depth 10 -Compress) -cne $expectedJson) { throw 'Serialization contract differs' }
            $result.Variants += [pscustomobject]@{
                Name=$variant; ProjectionMs=$projectionMs; SerializeMs=$serializeMs
                TotalMs=($projectionMs + $serializeMs); XmlBytes=[System.Text.Encoding]::UTF8.GetByteCount($xml)
                UsefulCount=$expected.Count
            }
            continue
        }
        $timer.Restart()
        Set-PSUCache -Key $key -Value @($payload) -Persist -Depth $depth -AbsoluteExpirationFromNow (New-TimeSpan -Minutes 30) -Integrated
        $setMs = $timer.Elapsed.TotalMilliseconds
        $reads = @(for ($readIndex = 0; $readIndex -lt $request.Reads; $readIndex++) {
            $timer.Restart()
            $cached = @(Get-PSUCache -Key $key -Integrated)
            $getMs = $timer.Elapsed.TotalMilliseconds
            $consumeMs = 0
            if ($variant -eq 'late') {
                $timer.Restart()
                $rows = if ($request.View -eq 'enabled-table') { @($cached | Where-Object Enabled -EQ $true | Select-Object -Property $properties) }
                    else { @($cached | Select-Object -Property $properties) }
                $consumeMs = $timer.Elapsed.TotalMilliseconds
            } else { $rows = $cached }
            if ((ConvertTo-Json -InputObject @($rows) -Depth 10 -Compress) -cne $expectedJson) { throw "Cache contract differs: $variant" }
            @{ GetMs=$getMs; ConsumeMs=$consumeMs; TotalMs=($getMs + $consumeMs) }
        })
        $readTotal = ($reads | Measure-Object -Property TotalMs -Sum).Sum
        $result.Variants += [pscustomobject]@{
            Name=$variant; Key=$key; ProjectionMs=$projectionMs; SetMs=$setMs; Reads=$reads
            ReadTotalMs=$readTotal; TotalMs=($projectionMs + $setMs + $readTotal)
            StoredCount=@($payload).Count; UsefulCount=$expected.Count
        }
    }
    $result.Depth = $depth
    $result.Properties = $properties
    $result.UsefulCount = $expected.Count
} elseif ($request.Family -in 'report','lookup') {
    $workloads = & "$PSScriptRoot/Get-AdminWorkload.ps1"
    $keys = @()
    if ($request.Family -eq 'lookup') {
        $keys = @(for ($i = 0; $i -lt $request.Queries; $i++) { 'USER{0:D5}' -f (($i * 37 + [int]($source.Count / 2)) % $source.Count) })
        $expectedRows = @($keys | ForEach-Object { "$($_.ToLower())@example.test" })
    } else {
        $expectedRows = @($source | ForEach-Object {
            [pscustomobject]@{ Account=$_.SamAccountName; Email=$_.Mail; Department=$_.Department; Enabled=$_.Enabled }
        })
    }
    $expectedJson = ConvertTo-Json -InputObject $expectedRows -Compress
    foreach ($variant in $request.Order) {
        $allocated = [GC]::GetAllocatedBytesForCurrentThread()
        $timer.Restart()
        $outcome = & $workloads[$variant] -Users $source -Keys $keys
        $elapsedMs = $timer.Elapsed.TotalMilliseconds
        $allocatedBytes = [GC]::GetAllocatedBytesForCurrentThread() - $allocated
        if ((ConvertTo-Json -InputObject @($outcome.Rows) -Compress) -cne $expectedJson) { throw "Scenario contract differs: $variant" }
        $result.Variants += [pscustomobject]@{Name=$variant;TotalMs=$elapsedMs;AllocatedBytes=$allocatedBytes;UsefulCount=@($outcome.Rows).Count}
    }
} else { throw 'Unknown scenario family' }
[pscustomobject]$result
