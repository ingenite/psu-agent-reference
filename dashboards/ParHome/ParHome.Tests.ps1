Describe 'PAR Home' {
    BeforeAll {
        # Stand-ins capture registrations and skip rendering; both cmdlets need a PSU host.
        function New-PSUApp {
            param($Name, $FilePath, $BaseUrl, $Environment, [switch] $AutoDeploy)
            [pscustomobject]@{ Name = $Name; FilePath = $FilePath; BaseUrl = $BaseUrl }
        }
        function New-UDApp { }

        $registrations = @(. (Join-Path $PSScriptRoot '../../.universal/dashboards.ps1'))
        . (Join-Path $PSScriptRoot 'ParHome.ps1')
    }

    It 'is registered as the home app' {
        $homeRegistration = @($registrations | Where-Object FilePath -eq 'dashboards/ParHome/ParHome.ps1')
        $homeRegistration | Should -HaveCount 1
        $homeRegistration.BaseUrl | Should -BeExactly '/home'
    }

    It 'links to every other registered app and nothing else' {
        $otherBaseUrls = $registrations | Where-Object FilePath -ne 'dashboards/ParHome/ParHome.ps1' | ForEach-Object BaseUrl
        ($Apps.Href | Sort-Object) | Should -Be ($otherBaseUrls | Sort-Object)
    }
}
