# Experimental only; not reference material for creating production PSU resources.
New-UDApp -Title 'PAR benchmarks' -Content {
    New-UDTypography -Text 'PAR benchmarks: deterministic inline callback'
    New-UDButton -Id 'benchmark-next' -Text 'Run next sample' -OnClick {
        # Owner authorized .NET timing for this benchmark. Work stays inline in the callback.
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        $requests = @(Get-Content 'C:/dev-psu/bench-results/dashboard-plan.json' -Raw | ConvertFrom-Json)
        $index = [int]$Session:BenchmarkIndex
        if ($index -ge $requests.Count) { Show-UDToast -Message 'Plan complete'; return }
        $request = $requests[$index]
        $Session:BenchmarkIndex = $index + 1
        $result = & 'C:/dev-psu/Repository/tools/benchmarks/Invoke-Workload.ps1' -RequestJson ($request | ConvertTo-Json -Compress)
        $row = @{ Request=$request; Result=$result; CallbackMs=$timer.Elapsed.TotalMilliseconds; Utc=(Get-Date).ToUniversalTime().ToString('o') }
        $row | ConvertTo-Json -Depth 20 -Compress | Set-Content "C:/dev-psu/bench-results/$($request.Id).json"
        Show-UDToast -Message "Completed $($request.Id)"
    }
    New-UDButton -Id 'benchmark-load' -Text 'Run concurrent sample' -OnClick {
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        $request = @{ Id="dashboard-load-$([guid]::NewGuid().ToString('N'))"; Kind='hash'; Iterations=100000; Label='hash-100000' }
        $result = & 'C:/dev-psu/Repository/tools/benchmarks/Invoke-Workload.ps1' -RequestJson ($request | ConvertTo-Json -Compress)
        $row = @{ Request=$request; Result=$result; CallbackMs=$timer.Elapsed.TotalMilliseconds; Utc=(Get-Date).ToUniversalTime().ToString('o') }
        $row | ConvertTo-Json -Depth 20 -Compress | Set-Content "C:/dev-psu/bench-results/$($request.Id).json"
        Show-UDToast -Message "Completed $($request.Id)"
    }
}
