# Experimental only; not reference material for creating production PSU resources.
# Owner authorized .NET serialization measurement. This is a local control, not PSU storage time.
param([int] $Count, [int] $Size)
$values = @(for ($i = 0; $i -lt $Count; $i++) { "item-$i|" + ('x' * $Size) })
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$xml = [System.Management.Automation.PSSerializer]::Serialize($values, 20)
$serializeMs = $timer.Elapsed.TotalMilliseconds
$timer.Restart()
$read = [System.Management.Automation.PSSerializer]::Deserialize($xml)
$deserializeMs = $timer.Elapsed.TotalMilliseconds
if ($read.Count -ne $values.Count) { throw 'Serialization count differs' }
for ($i = 0; $i -lt $values.Count; $i++) { if ($values[$i] -cne $read[$i]) { throw 'Serialization value differs' } }
@{ SerializeMs=$serializeMs; DeserializeMs=$deserializeMs; XmlBytes=[System.Text.Encoding]::UTF8.GetByteCount($xml); Count=$Count }
