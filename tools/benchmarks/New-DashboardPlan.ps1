# Experimental only; not reference material for creating production PSU resources.
<#
.SYNOPSIS
Creates the seeded plan consumed one sample per click by the benchmark app.
.NOTES
Restart the benchmark app before running a replaced plan to reset session indexes.
Load button always runs 100,000 hashes. Begin with four sequential clicks (first warm-up),
then four rounds of simultaneous clicks from four tabs (first round warm-up).
#>
[CmdletBinding()]
param([ValidatePattern('^[a-zA-Z0-9-]+$')][string] $Prefix='dashboard', [int] $Repetitions=5, [int] $Seed=731)
$ErrorActionPreference = 'Stop'
Get-Random -SetSeed $Seed | Out-Null
$plan = @(foreach ($block in 0..$Repetitions) {
    foreach ($iterations in (0,10000,100000 | Get-Random -Shuffle)) {
        @{Id="$Prefix-b$block-hash-$iterations";Kind='hash';Iterations=$iterations;Block=$block;Warmup=($block -eq 0);Label="hash-$iterations"}
    }
})
$plan | ConvertTo-Json -Depth 10 | Set-Content C:/dev-psu/bench-results/dashboard-plan.json
Write-Output 'Dashboard plan: C:/dev-psu/bench-results/dashboard-plan.json'
