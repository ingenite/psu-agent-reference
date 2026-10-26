#Requires -Version 7.1
#Requires -Modules @{ ModuleName = 'Microsoft.Graph.Users'; RequiredVersion = '2.41.2' }

<#
.SYNOPSIS
Investigates SDK user models offline, without authentication or Graph requests.
.DESCRIPTION
Writes synthetic inputs, installed command help, property metadata, construction
and serialization comparisons, and an environment summary to tools/output/.
Compares direct property assignment, JSON deserialization, and dictionary
deserialization. Includes omitted, null, empty, whitespace, true, and false values.
No Microsoft Graph service commands are invoked.
.INPUTS
None
.OUTPUTS
System.String

Brief result-file locations. A failed required comparison raises an error after
results are saved. SDK default serialization is investigated, not assumed safe.
.EXAMPLE
./tools/factories/Test-EntraUserModel.ps1
Writes offline discovery evidence under tools/output/ from the repository root.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$outputDirectory = Join-Path $PSScriptRoot '../output'
$null = New-Item -Path $outputDirectory -ItemType Directory -Force
$inputPath = Join-Path $outputDirectory 'entra-user-model-inputs.json'
$helpPath = Join-Path $outputDirectory 'entra-user-model-help.txt'
$propertyPath = Join-Path $outputDirectory 'entra-user-model-properties.csv'
$comparisonPath = Join-Path $outputDirectory 'entra-user-model-comparisons.csv'
$summaryPath = Join-Path $outputDirectory 'entra-user-model-summary.json'

@(
    Get-Help Get-MgUser -Full | Out-String -Width 160
    Get-Help New-MgUser -Parameter BodyParameter | Out-String -Width 160
) | Set-Content -LiteralPath $helpPath -Encoding utf8

$propertyMap = [ordered]@{
    id = 'Id'
    displayName = 'DisplayName'
    userPrincipalName = 'UserPrincipalName'
    mail = 'Mail'
    accountEnabled = 'AccountEnabled'
}
$inputs = @(
    @{ Scenario = 'Enabled'; Properties = @{
        id = '10000000-0000-4000-8000-000000000001'
        displayName = 'Alex Example'
        userPrincipalName = 'alex@example.invalid'
        mail = 'alex@example.invalid'
        accountEnabled = $true
    } },
    @{ Scenario = 'Disabled'; Properties = @{
        id = '10000000-0000-4000-8000-000000000002'
        displayName = 'Blair Sample'
        userPrincipalName = 'blair@example.invalid'
        mail = $null
        accountEnabled = $false
    } },
    @{ Scenario = 'Null'; Properties = @{
        id = '10000000-0000-4000-8000-000000000003'
        displayName = $null; userPrincipalName = $null; mail = $null; accountEnabled = $null
    } },
    @{ Scenario = 'Empty'; Properties = @{
        id = '10000000-0000-4000-8000-000000000004'
        displayName = ''; userPrincipalName = ''; mail = ''; accountEnabled = $null
    } },
    @{ Scenario = 'Whitespace'; Properties = @{
        id = '10000000-0000-4000-8000-000000000005'
        displayName = '   '; userPrincipalName = '   '; mail = '   '; accountEnabled = $false
    } },
    @{ Scenario = 'Omitted'; Properties = @{ id = '10000000-0000-4000-8000-000000000006' } }
)
$inputs | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $inputPath -Encoding utf8
$savedInputs = @(Get-Content -LiteralPath $inputPath -Raw | ConvertFrom-Json -AsHashtable)

# Session approval covers offline SDK construction, serialization, and reflection.
$modelType = [Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser]
$propertyMetadata = @(
    $modelType.GetProperties() | Select-Object Name,
        @{ Name = 'Type'; Expression = { $_.PropertyType.FullName } }, CanRead, CanWrite,
        @{ Name = 'Selected'; Expression = { $_.Name -in $propertyMap.Values } }
)
$propertyMetadata | Export-Csv -LiteralPath $propertyPath -NoTypeInformation -Encoding utf8

$comparisons = @(
    foreach ($inputRecord in $savedInputs) {
        $source = $inputRecord.Properties
        foreach ($construction in @('PropertyAssignment', 'FromJsonString', 'DeserializeFromDictionary')) {
            $user = switch ($construction) {
                'PropertyAssignment' {
                    $model = $modelType::new()
                    foreach ($jsonName in $source.Keys) {
                        $model.($propertyMap[$jsonName]) = $source[$jsonName]
                    }
                    $model
                }
                'FromJsonString' {
                    $modelType::FromJsonString((ConvertTo-Json -InputObject $source -Depth 3))
                }
                'DeserializeFromDictionary' { $modelType::DeserializeFromDictionary($source) }
            }

            $selected = [ordered]@{}
            foreach ($jsonName in $propertyMap.Keys) {
                $selected[$jsonName] = $user.($propertyMap[$jsonName])
            }
            $routes = @(
                @{ Name = 'Construction'; User = $user },
                @{ Name = 'SdkDefault'; User = $modelType::FromJsonString($user.ToJsonString()) },
                @{ Name = 'SdkIncludeReadOnly'; User = $modelType::FromJsonString(
                    $user.ToJson($null, [Microsoft.Graph.PowerShell.Runtime.SerializationMode]::IncludeReadOnly).ToString()
                ) },
                @{ Name = 'SelectedProperties'; User = $modelType::FromJsonString(
                    (ConvertTo-Json -InputObject $selected -Depth 3)
                ) }
            )
            foreach ($route in $routes) {
                foreach ($jsonName in $propertyMap.Keys) {
                    $expected = ConvertTo-Json -InputObject $source[$jsonName] -Compress
                    $actual = ConvertTo-Json -InputObject $route.User.($propertyMap[$jsonName]) -Compress
                    [pscustomobject]@{
                        Scenario = $inputRecord.Scenario
                        Construction = $construction
                        Route = $route.Name
                        Property = $propertyMap[$jsonName]
                        Expected = $expected
                        Actual = $actual
                        Passed = $expected -ceq $actual
                        ModelCompatible = $route.User -is [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphUser]
                    }
                }
            }
        }
    }
)
$comparisons | Export-Csv -LiteralPath $comparisonPath -NoTypeInformation -Encoding utf8
$routeSummaries = @(
    $comparisons | Group-Object Construction, Route | ForEach-Object {
        [pscustomobject]@{
            Construction = $_.Group[0].Construction
            Route = $_.Group[0].Route
            Checks = $_.Count
            Failures = @($_.Group | Where-Object { -not $_.Passed -or -not $_.ModelCompatible }).Count
        }
    }
)
$requiredFailures = @($comparisons | Where-Object {
    $_.Construction -eq 'FromJsonString' -and $_.Route -in @('Construction', 'SelectedProperties') -and
    (-not $_.Passed -or -not $_.ModelCompatible)
})
[ordered]@{
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    Modules = @(Get-Module Microsoft.Graph.Users, Microsoft.Graph.Authentication |
        Select-Object Name, @{ Name = 'Version'; Expression = { $_.Version.ToString() } }, ModuleBase, Path)
    ModelType = $modelType.FullName
    SelectedProperties = @($propertyMetadata | Where-Object Selected)
    ReadOnlyProperties = @($propertyMetadata | Where-Object { -not $_.CanWrite } | Select-Object -ExpandProperty Name)
    ScenarioCount = $savedInputs.Count
    ComparisonCount = $comparisons.Count
    Routes = $routeSummaries
    RequiredChecks = 'JSON construction and selected-property JSON round trips preserve values and model compatibility.'
    RequiredFailureCount = $requiredFailures.Count
    Limitation = 'Offline SDK behavior only; no authentication, tenant requests, or identity mapping.'
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryPath -Encoding utf8

Write-Output "Offline user-model probe results: $summaryPath"
Write-Output "Inputs, help, properties, and comparisons: $outputDirectory/entra-user-model-*"
if ($requiredFailures.Count -gt 0) {
    throw "User-model probe found $($requiredFailures.Count) required failures. See $comparisonPath."
}
