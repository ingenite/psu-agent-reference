# With ScriptBaseFolder set to 'scripts', -Path is relative to that folder; repeating 'scripts/' creates a nested path.
New-PSUScript -Name 'Show-HelloWorld.ps1' -Path 'Show-HelloWorld.ps1' -Environment 'PowerShell 7'
New-PSUScript -Name 'Get-VolumeSpaceReport.ps1' -Path 'Get-VolumeSpaceReport.ps1' -Environment 'PowerShell 7' -Description 'Software-design reference: synthetic volume-space report.'
