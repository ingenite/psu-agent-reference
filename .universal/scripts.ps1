# With ScriptBaseFolder set to 'scripts', -Path is relative to that folder; repeating 'scripts/' creates a nested path.
New-PSUScript -Name 'Show-HelloWorld.ps1' -Path 'Show-HelloWorld.ps1' -Environment 'PowerShell 7'
