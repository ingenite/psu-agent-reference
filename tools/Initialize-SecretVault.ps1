#Requires -Modules Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore

Register-SecretVault -Name 'psu-agent-reference' -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

# First use may prompt to create a SecretStore password.
Get-SecretStoreConfiguration

# These settings affect the current user's entire SecretStore.
# Passwordless access is for development, not production vaults.
Set-SecretStoreConfiguration -Authentication None -Interaction None
