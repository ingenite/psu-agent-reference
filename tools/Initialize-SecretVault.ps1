#Requires -Modules Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore

<#
.SYNOPSIS
Registers the contributor-local project vault and configures passwordless SecretStore access.
.DESCRIPTION
Requires Microsoft.PowerShell.SecretManagement and Microsoft.PowerShell.SecretStore.
Registers psu-agent-reference as the default vault, reads SecretStore configuration,
then sets Authentication and Interaction to None. These settings affect the current
user's entire SecretStore, including use outside this project. First use may prompt
for a password. This is development tooling, not a PSU runtime prerequisite.
.INPUTS
None
.OUTPUTS
Microsoft.PowerShell.SecretStore.SecureStoreConfig

The configuration reported before the settings change. Underlying cmdlets may
also emit status or prompts; output is not proof of the resulting configuration.
.NOTES
Run only when explicitly intending to change the current user's credential-store
configuration. Do not run as a routine verification check.
#>
Register-SecretVault -Name 'psu-agent-reference' -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

# First use may prompt to create a SecretStore password.
Get-SecretStoreConfiguration

# These settings affect the current user's entire SecretStore.
# Passwordless access is for development, not production vaults.
Set-SecretStoreConfiguration -Authentication None -Interaction None
