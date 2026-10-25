#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Microsoft.Graph.DeviceManagement'; RequiredVersion = '2.41.2' }
<#
.SYNOPSIS
Checks synthetic managed-device construction and JSON round trips without Graph requests.
.DESCRIPTION
Writes fixtures, property metadata, comparison results, and a summary to tools/output/.
Uses only synthetic records. No authentication or Microsoft Graph commands are invoked.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$outputDirectory = Join-Path $PSScriptRoot '../output'
$null = New-Item -Path $outputDirectory -ItemType Directory -Force
$fixturePath = Join-Path $outputDirectory 'intune-device-model-fixtures.json'
$comparisonPath = Join-Path $outputDirectory 'intune-device-model-comparisons.csv'
$propertyPath = Join-Path $outputDirectory 'intune-device-model-properties.csv'
$summaryPath = Join-Path $outputDirectory 'intune-device-model-summary.json'

$propertyMap = [ordered]@{
    id = 'Id'
    userId = 'UserId'
    deviceName = 'DeviceName'
    enrolledDateTime = 'EnrolledDateTime'
    lastSyncDateTime = 'LastSyncDateTime'
    operatingSystem = 'OperatingSystem'
    osVersion = 'OSVersion'
    emailAddress = 'EmailAddress'
    azureADDeviceId = 'AzureAdDeviceId'
    userPrincipalName = 'UserPrincipalName'
    model = 'Model'
    manufacturer = 'Manufacturer'
    serialNumber = 'SerialNumber'
    userDisplayName = 'UserDisplayName'
    deviceEnrollmentType = 'DeviceEnrollmentType'
}
$propertyNames = @($propertyMap.Values)
$datePropertyNames = @('EnrolledDateTime', 'LastSyncDateTime')

function ConvertTo-ComparisonValue {
    param(
        [AllowNull()]
        $Value,
        [string] $PropertyName
    )

    if ($null -eq $Value) {
        return 'null'
    }

    if ($PropertyName -in $datePropertyNames) {
        return ([datetimeoffset] $Value).UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
    }

    ConvertTo-Json -InputObject ([string] $Value) -Compress
}

$scenarios = @(
    @{ Name = 'Assigned'; UserId = '10000000-0000-4000-8000-000000000001' },
    @{ Name = 'NullUser'; UserId = $null },
    @{ Name = 'EmptyUser'; UserId = '' },
    @{ Name = 'WhitespaceUser'; UserId = '   ' },
    @{ Name = 'OmittedUserAndEnrollment' },
    @{ Name = 'AssignedWithOffset'; UserId = '10000000-0000-4000-8000-000000000001' }
)

$fixtures = @(
    for ($index = 0; $index -lt $scenarios.Count; $index++) {
        $scenario = $scenarios[$index]
        $number = $index + 1
        $properties = [ordered]@{
            id = '20000000-0000-4000-8000-{0:000000000000}' -f $number
            deviceName = 'SYNTH-WIN-{0:000}' -f $number
            enrolledDateTime = '2026-09-01T12:00:00Z'
            lastSyncDateTime = '2026-10-24T18:30:00Z'
            operatingSystem = 'Windows'
            osVersion = '10.0.26100.0'
            emailAddress = $null
            azureADDeviceId = '30000000-0000-4000-8000-{0:000000000000}' -f $number
            userPrincipalName = $null
            model = 'Synthetic Laptop'
            manufacturer = 'Fictional Devices'
            serialNumber = 'SYNTH-{0:000000}' -f $number
            userDisplayName = $null
        }

        if ($scenario.ContainsKey('UserId')) {
            $properties['userId'] = $scenario.UserId
            $properties['deviceEnrollmentType'] = 'unknown'
            if (-not [string]::IsNullOrWhiteSpace($scenario.UserId)) {
                $properties['emailAddress'] = 'alex@example.invalid'
                $properties['userPrincipalName'] = 'alex@example.invalid'
                $properties['userDisplayName'] = 'Alex Example'
            }
        }

        if ($scenario.Name -eq 'AssignedWithOffset') {
            $properties['enrolledDateTime'] = '2026-09-01T05:00:00-07:00'
            $properties['lastSyncDateTime'] = '2026-10-24T11:30:00-07:00'
        }

        [pscustomobject]@{ Scenario = $scenario.Name; Device = $properties }
    }
)

$fixtures | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $fixturePath -Encoding utf8
$savedFixtures = @(Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json -AsHashtable)

# Owner approved SDK model construction and .NET discovery for this offline probe in this session.
$modelType = [Microsoft.Graph.PowerShell.Models.MicrosoftGraphManagedDevice]
$modelType.GetProperties() |
    Where-Object Name -In $propertyNames |
    Select-Object Name, @{ Name = 'Type'; Expression = { $_.PropertyType.FullName } }, CanRead, CanWrite |
    Export-Csv -LiteralPath $propertyPath -NoTypeInformation -Encoding utf8

$comparisons = @(
    foreach ($fixture in $savedFixtures) {
        $source = $fixture.Device
        $sourceJson = ConvertTo-Json -InputObject $source -Depth 5
        $constructionMethods = @('FromJsonString', 'DeserializeFromDictionary')

        foreach ($constructionMethod in $constructionMethods) {
            $device = if ($constructionMethod -eq 'FromJsonString') {
                $modelType::FromJsonString($sourceJson)
            }
            else {
                $modelType::DeserializeFromDictionary($source)
            }

            $selectedProperties = [ordered]@{}
            foreach ($jsonName in $propertyMap.Keys) {
                $value = $device.($propertyMap[$jsonName])
                if ($jsonName -eq 'deviceEnrollmentType' -and $null -ne $value) {
                    $value = [string] $value
                }
                $selectedProperties[$jsonName] = $value
            }

            $routes = @(
                @{ Name = 'Construction'; Device = $device },
                @{ Name = 'SdkDefault'; Device = $modelType::FromJsonString($device.ToJsonString()) },
                @{
                    Name = 'SdkIncludeReadOnly'
                    Device = $modelType::FromJsonString(
                        $device.ToJson($null, [Microsoft.Graph.PowerShell.Runtime.SerializationMode]::IncludeReadOnly).ToString()
                    )
                },
                @{
                    Name = 'SelectedProperties'
                    Device = $modelType::FromJsonString(
                        (ConvertTo-Json -InputObject $selectedProperties -Depth 5)
                    )
                }
            )

            foreach ($route in $routes) {
                foreach ($jsonName in $propertyMap.Keys) {
                    $propertyName = $propertyMap[$jsonName]
                    $expected = ConvertTo-ComparisonValue -Value $source[$jsonName] -PropertyName $propertyName
                    $actual = ConvertTo-ComparisonValue -Value $route.Device.$propertyName -PropertyName $propertyName
                    [pscustomobject]@{
                        Scenario = $fixture.Scenario
                        Construction = $constructionMethod
                        Route = $route.Name
                        Property = $propertyName
                        Expected = $expected
                        Actual = $actual
                        Passed = $expected -ceq $actual
                        ModelCompatible = $route.Device -is [Microsoft.Graph.PowerShell.Models.IMicrosoftGraphManagedDevice]
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
$requiredFailures = @(
    $comparisons | Where-Object {
        $_.Construction -eq 'FromJsonString' -and (-not $_.Passed -or -not $_.ModelCompatible)
    }
)

[ordered]@{
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    ProcessPath = (Get-Process -Id $PID).Path
    Modules = @(Get-Module Microsoft.Graph.DeviceManagement, Microsoft.Graph.Authentication |
        Select-Object Name, @{ Name = 'Version'; Expression = { $_.Version.ToString() } }, ModuleBase)
    ModelType = $modelType.FullName
    ScenarioCount = $savedFixtures.Count
    PropertyCount = $propertyNames.Count
    ComparisonCount = $comparisons.Count
    Routes = $routeSummaries
    RecommendedConstruction = 'FromJsonString'
    RequiredChecks = 'All FromJsonString routes must preserve the selected values and model interface.'
    RequiredFailureCount = $requiredFailures.Count
    Limitation = 'Offline SDK behavior only; no live tenant retrieval or enrollment mapping validated.'
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryPath -Encoding utf8

Write-Output "Offline model probe results: $summaryPath"
Write-Output "Fixtures: $fixturePath"
Write-Output "Property metadata: $propertyPath"
Write-Output "Comparisons: $comparisonPath"

if ($requiredFailures.Count -gt 0) {
    throw "Offline model probe found $($requiredFailures.Count) required comparison failures. See $comparisonPath."
}
