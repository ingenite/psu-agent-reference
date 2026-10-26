#Requires -Version 7.1
#Requires -Modules @{ ModuleName = 'Microsoft.Graph.Users'; RequiredVersion = '2.41.2' }

<#
.SYNOPSIS
Creates one synthetic Entra user SDK model without connecting to Graph.
.DESCRIPTION
Requires Microsoft.Graph.Users 2.41.2. Returns an offline source model without
writing files. Supply Id for repeatable records. Id is independent of display
name, UPN, mail, and CMDB person references; no identity mapping is performed.
Optional fields default to null. Null, empty, and whitespace optional strings
are preserved. JSON construction preserves explicit null strings in this SDK.
This is a descriptive source projection, not a request body for creating a user.
.PARAMETER Id
Nonblank string identifying the Entra user object. Defaults to a new GUID string.
Supplied IDs are opaque and preserved verbatim, without parsing or normalization.
.PARAMETER DisplayName
Required nonblank display name as a string. Not an identity key.
.PARAMETER UserPrincipalName
Sign-in name as a string or null. Defaults to null; not inferred from Mail.
.PARAMETER Mail
SMTP address as a string or null. Defaults to null; not inferred from UPN.
.PARAMETER AccountEnabled
Boolean true, false, or null. Defaults to null (unspecified), not enabled or
disabled. Strings and numbers are rejected rather than coerced to Booleans.
.INPUTS
None

Pipeline input is not accepted.
.OUTPUTS
Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser

One SDK model. Invalid identifiers, names, or optional value types terminate.
.EXAMPLE
./tools/factories/New-FakeEntraUser.ps1 -DisplayName 'Alex Example' `
    -Id '10000000-0000-4000-8000-000000000001' -UserPrincipalName 'alex@example.invalid'
Creates a repeatable offline user with unspecified mail and account state.
#>
[CmdletBinding()]
[OutputType('Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $DisplayName,

    [AllowNull()]
    [AllowEmptyString()]
    $Id = (New-Guid).ToString(),

    [AllowNull()]
    [AllowEmptyString()]
    $UserPrincipalName = $null,

    [AllowNull()]
    [AllowEmptyString()]
    $Mail = $null,

    [AllowNull()]
    $AccountEnabled = $null
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$properties = [ordered]@{
    id = $Id
    displayName = $DisplayName
    userPrincipalName = $UserPrincipalName
    mail = $Mail
    accountEnabled = $AccountEnabled
}
foreach ($propertyName in @('id', 'displayName', 'userPrincipalName', 'mail')) {
    $value = $properties[$propertyName]
    if ($null -ne $value -and $value -isnot [string]) {
        throw "$propertyName must be a string or null."
    }
    if ($propertyName -in @('id', 'displayName') -and ($null -eq $value -or $value.Trim() -eq '')) {
        throw "$propertyName must be a nonblank string."
    }
}
if ($null -ne $AccountEnabled -and $AccountEnabled -isnot [bool]) {
    throw 'accountEnabled must be a Boolean or null.'
}

$json = ConvertTo-Json -InputObject $properties -Depth 3

# Session approval covers offline SDK construction; JSON preserves explicit null strings.
[Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser]::FromJsonString($json)
