#Requires -Version 7.4

<#
.SYNOPSIS
Generates a 256-bit JWT signing key as a hexadecimal string.
.DESCRIPTION
Requires PowerShell 7.4 or later. Generates 32 random bytes and returns their
lowercase hexadecimal representation. Does not configure PSU or store the key.
.INPUTS
None
.OUTPUTS
System.String

One 64-character lowercase hexadecimal string. Treat the result as secret material.
.EXAMPLE
$signingKey = ./tools/New-JwtSigningKey.ps1
Captures a new key from the repository root without displaying it.
#>
# PowerShell 7.4+: Get-SecureRandom provides cryptographically secure randomness.
$keyBytes = Get-SecureRandom -Minimum 0 -Maximum 256 -Count 32
($keyBytes | ForEach-Object { '{0:x2}' -f $_ }) -join ''
