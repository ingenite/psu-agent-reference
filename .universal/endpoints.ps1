New-PSUEndpoint -Url '/api/par/v1/hello' -Method 'GET' -Endpoint {
    "Hello"
}
New-PSUEndpoint -Url '/api/par/v1/design/volume-space' -Method 'GET' -Path 'Get-VolumeSpaceReport.ps1' -Environment 'PowerShell 7' -Description 'Software-design reference: synthetic volume-space report.'
