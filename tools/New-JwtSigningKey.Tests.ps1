Describe 'New-JwtSigningKey' {
    BeforeAll {
        $sampleSize = 25
        $samples = @(
            foreach ($invocation in 1..$sampleSize) {
                [pscustomobject]@{
                    OutputItems = @(& "$PSScriptRoot/New-JwtSigningKey.ps1")
                }
            }
        )
    }

    It 'returns exactly one string per invocation' {
        foreach ($sample in $samples) {
            $sample.OutputItems | Should -HaveCount 1
            $sample.OutputItems[0] | Should -BeOfType [string]
        }
    }

    It 'returns exactly 64 hexadecimal characters per key' {
        foreach ($sample in $samples) {
            $sample.OutputItems[0] | Should -MatchExactly '\A[0-9a-f]{64}\z'
        }
    }

    It 'returns distinct keys across 25 sequential invocations' {
        $samples.OutputItems | Select-Object -Unique | Should -HaveCount $sampleSize
    }
}
