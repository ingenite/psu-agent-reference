# Experimental only; not reference material for creating production PSU resources.
<#
.SYNOPSIS
Creates deterministic synthetic directory-user records, without querying AD.
.NOTES
These are PSCustomObjects with familiar AD property names, not ADUser instances.
Every fifth record is enabled, including the first. No real identities, directory data, or credentials are used.
#>
[CmdletBinding()]
param([ValidateRange(1,10000)][int] $Count)
for ($i = 0; $i -lt $Count; $i++) {
    $account = 'user{0:D5}' -f $i
    $record = [ordered]@{
        SamAccountName = $account
        DisplayName = "Demonstration User $i"
        UserPrincipalName = "$account@example.test"
        Mail = "$account@example.test"
        Enabled = ($i % 5 -eq 0)
        Department = @('Support','Finance','Engineering','Sales')[$i % 4]
        DistinguishedName = "CN=$account,OU=Demo,DC=example,DC=test"
        GivenName = 'Demonstration'
        Surname = "User$i"
        Manager = 'CN=user00000,OU=Demo,DC=example,DC=test'
        Title = 'Demonstration account'
        Office = 'Example office'
        Company = 'Example organization'
        Description = ('Synthetic directory description. ' * 8)
        MemberOf = @(for ($group = 0; $group -lt 10; $group++) { "CN=Group$group,OU=Groups,DC=example,DC=test" })
        ProxyAddresses = @("SMTP:$account@example.test", "smtp:$account@alias.example.test")
        TelephoneNumber = '555-0100'
        EmployeeId = "DEMO-$i"
        StreetAddress = '1 Demonstration Street'
        City = 'Example city'
        Country = 'Example country'
        PostalCode = '00000'
        HomeDirectory = "\\example.test\demo\$account"
        ScriptPath = 'demonstration.ps1'
    }
    foreach ($extension in 1..15) { $record["extensionAttribute$extension"] = "Example extension $extension " + ('x' * 64) }
    [pscustomobject]$record
}
