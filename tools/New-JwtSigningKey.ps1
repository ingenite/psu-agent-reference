#Requires -Version 7.4

# Generates a 256-bit JWT signing key as a 64-character hex string.
# PowerShell 7.4+: Get-SecureRandom provides cryptographically secure randomness.
$keyBytes = Get-SecureRandom -Minimum 0 -Maximum 256 -Count 32
($keyBytes | ForEach-Object { '{0:x2}' -f $_ }) -join ''
