Describe 'PAR IT Internal' {
    BeforeAll {
        $dataModulePath = Join-Path $PSScriptRoot '../../modules/ParData/ParData.psd1'
        $reportModulePath = Join-Path $PSScriptRoot '../../modules/ParReports/ParReports.psd1'
        $appModulePath = Join-Path $PSScriptRoot 'ParITInternal.psm1'
        $fixtureDirectory = Join-Path $PSScriptRoot '../../data'
        $existingFixtureVariable = Get-Variable -Name PAR_FixturePaths -Scope Global -ErrorAction SilentlyContinue

        function Import-TestAppData {
            Remove-Module ParData -ErrorAction SilentlyContinue
            Import-Module $dataModulePath -ArgumentList $fixturePaths -Force
        }

        function ConvertTo-TestSnapshotJson {
            param($Snapshot)

            # Compare source projections instead of serializing the SDK models' full property graphs.
            [pscustomobject]@{
                Devices = @($Snapshot.Inputs.IntuneDevice | Select-Object Id, UserId, DeviceName, SerialNumber, UserDisplayName, UserPrincipalName)
                Users = @($Snapshot.Inputs.EntraUser | Select-Object Id, DisplayName, UserPrincipalName, Mail, AccountEnabled)
                Assets = $Snapshot.Inputs.CmdbAsset
                Mappings = $Snapshot.Inputs.PersonMapping
                Outcomes = @($Snapshot.DeviceAssignments | Select-Object RecordNumber, IntuneDeviceId, Outcome, Reason)
                MissingPrimaryUser = @($Snapshot.WithoutPrimaryUser | Select-Object RecordNumber, IntuneDeviceId)
            } | ConvertTo-Json -Depth 8 -Compress
        }
    }

    BeforeEach {
        Remove-Variable -Name PAR_FixturePaths -Scope Global -ErrorAction SilentlyContinue
        $fixturePaths = @{
            IntuneDevice = Join-Path $TestDrive 'intune.csv'
            CmdbAsset = Join-Path $TestDrive 'cmdb.csv'
            EntraUser = Join-Path $TestDrive 'entra.csv'
            PersonMapping = Join-Path $TestDrive 'mappings.csv'
        }
        Copy-Item -LiteralPath (Join-Path $fixtureDirectory 'intune-devices.csv') -Destination $fixturePaths.IntuneDevice
        Copy-Item -LiteralPath (Join-Path $fixtureDirectory 'cmdb-assets.csv') -Destination $fixturePaths.CmdbAsset
        Copy-Item -LiteralPath (Join-Path $fixtureDirectory 'entra-users.csv') -Destination $fixturePaths.EntraUser
        Copy-Item -LiteralPath (Join-Path $fixtureDirectory 'cmdb-person-mappings.csv') -Destination $fixturePaths.PersonMapping
        Import-TestAppData
        Import-Module $reportModulePath -Force
        Import-Module $appModulePath -Force
    }

    AfterAll {
        Remove-Module ParITInternal, ParITInternalCommands, ParReports, ParData -ErrorAction SilentlyContinue
        Remove-Variable -Name PAR_FixturePaths -Scope Global -ErrorAction SilentlyContinue
        if ($null -ne $existingFixtureVariable) {
            Set-Variable -Name PAR_FixturePaths -Scope Global -Value $existingFixtureVariable.Value
        }
    }

    Context 'Companion command identity' {
        It 'exposes exactly the ten PITI commands through the companion' {
            $expectedNames = @(
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
            $commands = @(Get-Command -Module ParITInternal)
            $commands | Should -HaveCount 10
            ($commands.Name | Sort-Object) | Should -Be ($expectedNames | Sort-Object)
            foreach ($name in $expectedNames) {
                Get-Command -Name ($name -replace '-PITI', '-') -ListImported -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
                Get-Command -Name ($name -replace '-PITI', '-Par') -ListImported -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            }
        }

        It 'resolves help and callback-facing helpers by their public names' {
            (Get-Help Get-PITIDeviceAssignmentSnapshot).Synopsis | Should -BeLike '*complete synthetic device-assignment*'
            & { Get-PITIAssignmentOutcomeText -Outcome MissingAssignment } | Should -BeExactly 'Missing assignment'
            & { Get-PITIAssignmentReasonText -Reason MultipleMatchingCmdbRecords } | Should -BeLike '*Multiple CMDB assets*'
        }
    }

    Context 'PAR IT Internal offline composition' {
        It 'uses the shared default data for both report entry points without report-specific configuration' {
            Remove-Module ParData
            Import-Module $dataModulePath -Force
            $snapshot = Get-PITIDeviceAssignmentSnapshot
            $report = @(Get-ParIntuneDeviceWithoutPrimaryUserReport)

            $snapshot.DeviceAssignments | Should -HaveCount 11
            $snapshot.WithoutPrimaryUser.IntuneDeviceId | Should -Be $report.IntuneDeviceId
            $snapshot.Inputs.IntuneDevice[0].DeviceName | Should -BeExactly 'SYNTH-COMPARE-MATCH'
            $snapshot.DeviceAssignments[1].Outcome | Should -BeExactly 'Mismatch'
        }

        It 'composes actual SDK records and preserves every existing comparison outcome and reason' {
            $snapshot = Get-PITIDeviceAssignmentSnapshot
            $expected = @(Compare-ParDeviceAssignedUser -InputObject $snapshot.Inputs.IntuneDevice -CmdbAsset $snapshot.Inputs.CmdbAsset -EntraUser $snapshot.Inputs.EntraUser -PersonMapping $snapshot.Inputs.PersonMapping)

            $snapshot.DeviceAssignments | Should -HaveCount 11
            $snapshot.DeviceAssignments.IntuneDeviceId | Should -Be $snapshot.Inputs.IntuneDevice.Id
            $snapshot.DeviceAssignments.Outcome | Should -Be $expected.Outcome
            $snapshot.DeviceAssignments.Reason | Should -Be $expected.Reason
            $snapshot.Inputs.IntuneDevice[0] | Should -BeOfType 'Microsoft.Graph.PowerShell.Models.MicrosoftGraphManagedDevice'
            $snapshot.Inputs.EntraUser[0] | Should -BeOfType 'Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser'
            $snapshot.DeviceAssignments.RecordNumber | Should -Be @(1..11)
        }

        It 'shows both accounts in a mismatch while retaining the recorded primary-user context' {
            $row = (Get-PITIDeviceAssignmentSnapshot).DeviceAssignments[1]
            $row.Outcome | Should -BeExactly 'Mismatch'
            $row.IntuneDevice.UserDisplayName | Should -BeExactly 'Blair Sample'
            $row.IntuneDevice.UserPrincipalName | Should -BeExactly 'blair@example.invalid'
            $row.IntunePrimaryUser.EntraCandidates[0].DisplayName | Should -BeExactly 'Blair Sample'
            $row.IntunePrimaryUser.EntraCandidates[0].AccountEnabled | Should -BeFalse
            $row.CmdbAssignedUsers[0].EntraCandidates[0].DisplayName | Should -BeExactly 'Alex Example'
            $row.CmdbAssignedUsers[0].MappingCandidates[0].personReference | Should -BeExactly 'COMPARE-PERSON-ALEX'
        }

        It 'connects missing-primary-user rows to the same investigations, including the intentional shared device' {
            $snapshot = Get-PITIDeviceAssignmentSnapshot
            $snapshot.WithoutPrimaryUser | Should -HaveCount 4
            foreach ($entry in $snapshot.WithoutPrimaryUser) {
                $entry.Investigation | Should -Be $snapshot.DeviceAssignments[$entry.RecordNumber - 1]
                $entry.IntuneDeviceId | Should -BeExactly $entry.Report.IntuneDeviceId
                $entry.Investigation.IntunePrimaryUser.Reason | Should -BeExactly 'BlankUserId'
            }
            $shared = @($snapshot.WithoutPrimaryUser | Where-Object { $_.Report.DeviceName -eq 'SYNTH-COMPARE-SHARED' })
            $shared | Should -HaveCount 1
            $shared[0].Investigation.Reason | Should -BeExactly 'BothAssignmentsMissing'
        }

        It 'resolves every ambiguous asset independently without changing the unresolved comparison' {
            $row = (Get-PITIDeviceAssignmentSnapshot).DeviceAssignments[6]
            $row.Outcome | Should -BeExactly 'Unresolved'
            $row.Comparison.AssignedUserResolution | Should -BeNullOrEmpty
            $row.CmdbAssignedUsers | Should -HaveCount 2
            $row.CmdbAssignedUsers.CmdbAssetId | Should -Be @('COMPARE-ASSET-007A', 'COMPARE-ASSET-007B')
            $row.CmdbAssignedUsers.Outcome | Should -Be @('Unique', 'Unique')
            foreach ($resolution in $row.CmdbAssignedUsers) {
                $resolution.EntraCandidates[0].DisplayName | Should -BeExactly 'Alex Example'
                $resolution.MappingCount | Should -Be 1
            }
        }

        It 'retains specific missing and ambiguous person or Entra evidence' {
            $rows = (Get-PITIDeviceAssignmentSnapshot).DeviceAssignments
            $rows[7].CmdbAssignedUsers[0].Reason | Should -BeExactly 'NoPersonMapping'
            $rows[8].CmdbAssignedUsers[0].Reason | Should -BeExactly 'MultiplePersonMappings'
            $rows[8].CmdbAssignedUsers[0].MappingCandidates | Should -HaveCount 2
            $rows[9].CmdbAssignedUsers[0].Reason | Should -BeExactly 'NoMatchingEntraUser'
            $rows[10].CmdbAssignedUsers[0].Reason | Should -BeExactly 'MultipleMatchingEntraUsers'
            $rows[10].CmdbAssignedUsers[0].EntraCandidates | Should -HaveCount 2
            @($rows[7..10] | Where-Object Outcome -ne 'Unresolved') | Should -HaveCount 0
        }

        It 'distinguishes missing Intune enrichment without redefining the ID comparison' {
            $users = @(Import-Csv -LiteralPath $fixturePaths.EntraUser | Where-Object id -ne '10000000-0000-4000-8000-000000000002')
            $users | Export-Csv -LiteralPath $fixturePaths.EntraUser -NoTypeInformation
            $row = (Get-PITIDeviceAssignmentSnapshot).DeviceAssignments[1]
            $row.Outcome | Should -BeExactly 'Mismatch'
            $row.IntunePrimaryUser.Outcome | Should -BeExactly 'Missing'
            $row.IntunePrimaryUser.Reason | Should -BeExactly 'NoMatchingEntraUser'
            $row.IntunePrimaryUser.EntraCandidates | Should -HaveCount 0
        }

        It 'retains duplicate Intune-side Entra IDs as ambiguous despite conflicting descriptive context' {
            $users = @(Import-Csv -LiteralPath $fixturePaths.EntraUser)
            $duplicate = [pscustomobject]@{
                id = " $($users[1].id) "; displayName = 'Different context'; userPrincipalName = 'other@example.invalid'; mail = ''; accountEnabled = 'True'
            }
            @($users; $duplicate) | Export-Csv -LiteralPath $fixturePaths.EntraUser -NoTypeInformation
            $row = (Get-PITIDeviceAssignmentSnapshot).DeviceAssignments[1]
            $row.Outcome | Should -BeExactly 'Mismatch'
            $row.IntunePrimaryUser.Outcome | Should -BeExactly 'Ambiguous'
            $row.IntunePrimaryUser.EntraCandidateCount | Should -Be 2
            $row.IntunePrimaryUser.EntraCandidates.DisplayName | Should -Be @('Blair Sample', 'Different context')
        }

        It 'uses literal normalized IDs rather than display fields or pattern matching: <UserId>' -ForEach @(
            @{ UserId = ' OPAQUE-ID '; CandidateId = 'opaque-id'; Expected = 'Unique' }
            @{ UserId = 'opaque-*'; CandidateId = 'opaque-id'; Expected = 'Missing' }
            @{ UserId = 'opaque-id'; CandidateId = 'opaque- id'; Expected = 'Missing' }
            @{ UserId = ' '; CandidateId = ' '; Expected = 'Missing' }
        ) {
            $devices = @(Import-Csv -LiteralPath $fixturePaths.IntuneDevice)
            $devices[0].userId = $UserId
            $devices | Export-Csv -LiteralPath $fixturePaths.IntuneDevice -NoTypeInformation
            $users = @(Import-Csv -LiteralPath $fixturePaths.EntraUser)
            $users[0].id = $CandidateId
            if ($CandidateId.Trim() -eq '') {
                # Blank Entra IDs are not valid ParData records; use supplied evidence for this isolated edge case.
                Mock Get-ParEntraUser -ModuleName ParITInternalCommands { [pscustomobject]@{ Id = ' '; UserPrincipalName = 'alex@example.invalid' } }
            }
            else { $users | Export-Csv -LiteralPath $fixturePaths.EntraUser -NoTypeInformation }
            $row = (Get-PITIDeviceAssignmentSnapshot).DeviceAssignments[0]
            $row.IntunePrimaryUser.Outcome | Should -BeExactly $Expected
        }

        It 'preserves repeated Intune IDs and serials as separate report entries with distinct record numbers' {
            $devices = @(Import-Csv -LiteralPath $fixturePaths.IntuneDevice)
            @($devices[2], $devices[2]) | Export-Csv -LiteralPath $fixturePaths.IntuneDevice -NoTypeInformation
            $snapshot = Get-PITIDeviceAssignmentSnapshot
            $snapshot.DeviceAssignments | Should -HaveCount 2
            $snapshot.WithoutPrimaryUser.RecordNumber | Should -Be @(1, 2)
            $snapshot.WithoutPrimaryUser[0].Investigation | Should -Be $snapshot.DeviceAssignments[0]
            $snapshot.WithoutPrimaryUser[1].Investigation | Should -Be $snapshot.DeviceAssignments[1]
            $snapshot.DeviceAssignments.IntuneDeviceId | Should -Be @($devices[2].id, $devices[2].id)
        }

        It 'holds existing evidence until another refresh and leaves source records unchanged' {
            $snapshot = Get-PITIDeviceAssignmentSnapshot
            $before = ConvertTo-TestSnapshotJson $snapshot
            $users = @(Import-Csv -LiteralPath $fixturePaths.EntraUser)
            $users[1].displayName = 'Updated Blair'
            $users | Export-Csv -LiteralPath $fixturePaths.EntraUser -NoTypeInformation
            $next = Get-PITIDeviceAssignmentSnapshot
            (ConvertTo-TestSnapshotJson $snapshot) | Should -BeExactly $before
            $next.DeviceAssignments[1].IntunePrimaryUser.EntraCandidates[0].DisplayName | Should -BeExactly 'Updated Blair'
            $snapshot.DeviceAssignments[1].IntuneDevice | Should -Be $snapshot.Inputs.IntuneDevice[1]
            $snapshot.DeviceAssignments[1].IntunePrimaryUser.EntraCandidates[0] | Should -Be $snapshot.Inputs.EntraUser[1]
        }

        It 'returns one successful snapshot with empty arrays when all inputs are empty' {
            foreach ($path in $fixturePaths.Values) { Set-Content -LiteralPath $path -Value '' -NoNewline }
            $received = @(Get-PITIDeviceAssignmentSnapshot)
            $received | Should -HaveCount 1
            $received[0].DeviceAssignments | Should -HaveCount 0
            $received[0].WithoutPrimaryUser | Should -HaveCount 0
            foreach ($property in $received[0].Inputs.PSObject.Properties) { $property.Value | Should -HaveCount 0 }
            ($received[0].DeviceAssignments -is [array]) | Should -BeTrue
            ($received[0].WithoutPrimaryUser -is [array]) | Should -BeTrue
        }

        It 'treats an empty <Source> as successful retrieval with existing missing-evidence behavior' -ForEach @(
            @{ Source = 'CmdbAsset'; Reason = 'CmdbAssetMissing' }
            @{ Source = 'EntraUser'; Reason = 'CmdbAssignedUserUnresolved' }
            @{ Source = 'PersonMapping'; Reason = 'CmdbAssignedUserUnresolved' }
        ) {
            Set-Content -LiteralPath $fixturePaths[$Source] -Value '' -NoNewline
            $snapshot = Get-PITIDeviceAssignmentSnapshot
            $snapshot.Inputs.$Source | Should -HaveCount 0
            $snapshot.DeviceAssignments | Should -HaveCount 11
            $snapshot.DeviceAssignments[0].Reason | Should -BeExactly $Reason
        }

        It 'retrieves each required source exactly once and never rereads when accessing investigation details' {
            $devices = @(Get-ParIntuneDevice)
            $assets = @(Get-ParCmdbAsset)
            $users = @(Get-ParEntraUser)
            $mappings = @(Get-ParCmdbPersonMapping)
            Mock Get-ParIntuneDevice -ModuleName ParITInternalCommands { $devices }
            Mock Get-ParCmdbAsset -ModuleName ParITInternalCommands { $assets }
            Mock Get-ParEntraUser -ModuleName ParITInternalCommands { $users }
            Mock Get-ParCmdbPersonMapping -ModuleName ParITInternalCommands { $mappings }
            $snapshot = Get-PITIDeviceAssignmentSnapshot
            $null = $snapshot.WithoutPrimaryUser[0].Investigation.IntuneDevice
            foreach ($name in @('Get-ParIntuneDevice', 'Get-ParCmdbAsset', 'Get-ParEntraUser', 'Get-ParCmdbPersonMapping')) {
                Should -Invoke $name -ModuleName ParITInternalCommands -Times 1 -Exactly
            }
        }
    }

    Context 'Shared report display rows' {
        It 'formats recorded and resolved assignments without changing comparison results' {
            $state = New-PITIDeviceAssignmentState
            $rows = @(ConvertTo-PITIDeviceAssignmentRow -Investigation $state.Snapshot.DeviceAssignments -SnapshotId $state.SnapshotId)

            $rows | Should -HaveCount 11
            $rows.RecordNumber | Should -Be $state.Snapshot.DeviceAssignments.RecordNumber
            $rows[1].PrimaryUserName | Should -BeExactly 'Blair Sample'
            $rows[1].PrimaryUser | Should -BeExactly 'blair@example.invalid'
            $rows[1].CmdbUserName | Should -BeExactly 'Alex Example'
            $rows[1].CmdbUserUpn | Should -BeExactly 'alex@example.invalid'
            $rows[1].Outcome | Should -BeExactly 'Mismatch'
            $rows[1].Reason | Should -BeExactly 'The Intune and CMDB assignments identify different Entra users.'
            $rows[2].Outcome | Should -BeExactly 'Missing assignment'
            $rows[3].CmdbSummary | Should -BeExactly 'Not assigned'
            $rows[5].CmdbSummary | Should -BeExactly 'No matching asset'
            $rows[6].CmdbSummary | Should -BeExactly '2 asset candidates'
            $rows[6].CmdbUserUpn | Should -BeNullOrEmpty
            $rows[7].CmdbSummary | Should -BeExactly 'Unresolved person'
            $state.Snapshot.DeviceAssignments[2].Outcome | Should -BeExactly 'MissingAssignment'
        }

        It 'uses only the supplied subset and retained evidence without reading sources again' {
            $state = New-PITIDeviceAssignmentState
            $investigations = @($state.Snapshot.WithoutPrimaryUser | ForEach-Object { $_.Investigation })
            foreach ($path in $fixturePaths.Values) { Remove-Item -LiteralPath $path }
            $rows = @(ConvertTo-PITIDeviceAssignmentRow -Investigation $investigations -SnapshotId $state.SnapshotId)

            $rows | Should -HaveCount 4
            $rows.RecordNumber | Should -Be $state.Snapshot.WithoutPrimaryUser.RecordNumber
            foreach ($row in $rows) {
                $row.SnapshotId | Should -BeExactly $state.SnapshotId
                $selected = Get-PITIDeviceInvestigation -State $state -SnapshotId $row.SnapshotId -RecordNumber $row.RecordNumber
                $selected.IntuneDeviceId | Should -BeExactly $row.IntuneDeviceId
            }
        }

        It 'preserves duplicate records and their investigation selection keys' {
            $devices = @(Import-Csv -LiteralPath $fixturePaths.IntuneDevice)
            @($devices[2], $devices[2]) | Export-Csv -LiteralPath $fixturePaths.IntuneDevice -NoTypeInformation
            $state = New-PITIDeviceAssignmentState
            $rows = @(ConvertTo-PITIDeviceAssignmentRow -Investigation $state.Snapshot.DeviceAssignments -SnapshotId $state.SnapshotId)

            $rows | Should -HaveCount 2
            $rows.RecordNumber | Should -Be @(1, 2)
            $rows.IntuneDeviceId | Should -Be @($devices[2].id, $devices[2].id)
            foreach ($row in $rows) {
                $selected = Get-PITIDeviceInvestigation -State $state -SnapshotId $row.SnapshotId -RecordNumber $row.RecordNumber
                $selected | Should -Be $state.Snapshot.DeviceAssignments[$row.RecordNumber - 1]
            }
        }

        It 'returns no display rows for a successfully empty selection' {
            @(ConvertTo-PITIDeviceAssignmentRow -Investigation @() -SnapshotId 'empty') | Should -HaveCount 0
        }
    }

    Context 'Report state and investigation selection' {
        It 'loads a complete state and gives each refresh a new identity' {
            $first = New-PITIDeviceAssignmentState
            $second = New-PITIDeviceAssignmentState
            $first.Status | Should -BeExactly 'Ready'
            $first.Snapshot.DeviceAssignments | Should -HaveCount 11
            $first.LoadedAt | Should -Not -BeNullOrEmpty
            $second.SnapshotId | Should -Not -BeExactly $first.SnapshotId
            Get-PITIDeviceInvestigation -State $second -SnapshotId $first.SnapshotId -RecordNumber '2' | Should -BeNullOrEmpty
        }

        It 'selects duplicate IDs by record position without rereading sources' {
            $devices = @(Import-Csv -LiteralPath $fixturePaths.IntuneDevice)
            $devices[1].id = $devices[0].id
            $devices | Export-Csv -LiteralPath $fixturePaths.IntuneDevice -NoTypeInformation
            $state = New-PITIDeviceAssignmentState
            Remove-Item -LiteralPath $fixturePaths.IntuneDevice
            $first = Get-PITIDeviceInvestigation -State $state -SnapshotId $state.SnapshotId -RecordNumber '1'
            $second = Get-PITIDeviceInvestigation -State $state -SnapshotId $state.SnapshotId -RecordNumber '2'
            $first.IntuneDeviceId | Should -BeExactly $second.IntuneDeviceId
            $first.Outcome | Should -BeExactly 'Match'
            $second.Outcome | Should -BeExactly 'Mismatch'
            $second | Should -Be $state.Snapshot.DeviceAssignments[1]
        }

        It 'rejects invalid record position <Position>' -ForEach @(
            @{ Position = '0' }, @{ Position = '-1' }, @{ Position = '12' },
            @{ Position = 'abc' }, @{ Position = '1.0' }, @{ Position = '9999999999999' }
        ) {
            $state = New-PITIDeviceAssignmentState
            Get-PITIDeviceInvestigation -State $state -SnapshotId $state.SnapshotId -RecordNumber $Position | Should -BeNullOrEmpty
        }

        It 'keeps successful empty retrieval distinct from failed refresh and clears previous results' {
            $header = Get-Content -LiteralPath $fixturePaths.IntuneDevice -TotalCount 1
            Set-Content -LiteralPath $fixturePaths.IntuneDevice -Value $header
            $state = New-PITIDeviceAssignmentState
            $state.Status | Should -BeExactly 'Ready'
            $state.Snapshot.DeviceAssignments | Should -HaveCount 0
            Remove-Item -LiteralPath $fixturePaths.PersonMapping
            $state = New-PITIDeviceAssignmentState -WarningAction SilentlyContinue
            $state.Status | Should -BeExactly 'Failed'
            $state.Snapshot | Should -BeNullOrEmpty
            $state.SnapshotId | Should -BeNullOrEmpty
            $state.LoadedAt | Should -BeNullOrEmpty
            Get-PITIDeviceInvestigation -State $state -SnapshotId 'expired' -RecordNumber '1' | Should -BeNullOrEmpty
            Get-PITIDeviceInvestigation -State $null -SnapshotId 'expired' -RecordNumber '1' | Should -BeNullOrEmpty
        }
    }

    Context 'PAR IT Internal failed refreshes' {
        It 'returns no partial result and leaves a previous snapshot intact when <Source> is unreadable' -ForEach @(
            @{ Source = 'IntuneDevice' }
            @{ Source = 'CmdbAsset' }
            @{ Source = 'EntraUser' }
            @{ Source = 'PersonMapping' }
        ) {
            $previous = Get-PITIDeviceAssignmentSnapshot
            $before = ConvertTo-TestSnapshotJson $previous
            Remove-Item -LiteralPath $fixturePaths[$Source]
            $received = @()
            $failure = $null
            try { Get-PITIDeviceAssignmentSnapshot | ForEach-Object { $received += $_ } }
            catch { $failure = $_ }
            $failure.Exception.Message | Should -BeLike '*Cannot read*fixture*'
            $received | Should -HaveCount 0
            (ConvertTo-TestSnapshotJson $previous) | Should -BeExactly $before
        }

        It 'emits no snapshot when <Command> emits records and then fails' -ForEach @(
            @{ Command = 'Get-ParIntuneDevice' }
            @{ Command = 'Get-ParCmdbAsset' }
            @{ Command = 'Get-ParEntraUser' }
            @{ Command = 'Get-ParCmdbPersonMapping' }
        ) {
            Mock $Command -ModuleName ParITInternalCommands { [pscustomobject]@{ Id = 'partial' }; throw 'Later source failure' }
            $received = @()
            $failure = $null
            try { Get-PITIDeviceAssignmentSnapshot | ForEach-Object { $received += $_ } }
            catch { $failure = $_ }
            $failure.Exception.Message | Should -BeLike '*Later source failure*'
            $received | Should -HaveCount 0
        }

        It 'promotes nonterminating errors from <Command> even when the caller requests silence' -ForEach @(
            @{ Command = 'Get-ParIntuneDevice' }
            @{ Command = 'Get-ParCmdbAsset' }
            @{ Command = 'Get-ParEntraUser' }
            @{ Command = 'Get-ParCmdbPersonMapping' }
        ) {
            # Use a real advanced function: Pester mock bodies do not inherit the caller's error preference.
            InModuleScope ParData -Parameters @{ SourceCommand = $Command } {
                param($SourceCommand)

                Set-Item -LiteralPath "Function:script:$SourceCommand" -Value {
                    [CmdletBinding()]
                    param()
                    Write-Error 'Source error'
                }
                { Get-PITIDeviceAssignmentSnapshot -ErrorAction SilentlyContinue } | Should -Throw '*Source error*'
            }
        }

        It 'buffers later investigation failures before returning a new snapshot' {
            Mock Resolve-ParCmdbAssignedUser -ModuleName ParITInternalCommands {
                param($InputObject, $PersonMapping, $EntraUser)
                if ($InputObject.assetId -contains 'COMPARE-ASSET-002') { throw 'Later investigation failure' }
                ParReports\Resolve-ParCmdbAssignedUser -InputObject $InputObject -PersonMapping $PersonMapping -EntraUser $EntraUser
            }
            $received = @()
            $failure = $null
            try { Get-PITIDeviceAssignmentSnapshot | ForEach-Object { $received += $_ } }
            catch { $failure = $_ }
            $failure.Exception.Message | Should -BeLike '*Later investigation failure*'
            $received | Should -HaveCount 0
        }
    }
}
