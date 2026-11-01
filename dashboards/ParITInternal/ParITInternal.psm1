Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# PSU loads this companion in app execution contexts, including deferred callbacks.
Import-Module (Join-Path $PSScriptRoot 'ParITInternalCommands.psm1') `
    -Prefix PITI -Scope Local -ErrorAction Stop

Export-ModuleMember -Function @(
    'Get-PITIDeviceAssignmentSnapshot'
    'New-PITIDeviceAssignmentState'
    'Get-PITIDeviceInvestigation'
    'ConvertTo-PITIDeviceAssignmentRow'
    'Show-PITIDeviceInvestigationDialog'
    'Get-PITIAssignmentReasonText'
    'Get-PITIAssignmentOutcomeText'
    'New-PITIEvidenceTable'
    'New-PITIEntraEvidence'
    'New-PITIAssignmentSummary'
)
