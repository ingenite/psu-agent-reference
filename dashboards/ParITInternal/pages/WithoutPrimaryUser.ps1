New-UDPage -Name 'Windows devices without a primary user' -Url '/without-primary-user' -AutoInclude -Content {
    New-UDStack -Direction column -Spacing 2 -Children {
        # Component links include the app base URL, unlike navigation and page URLs.
        New-UDLink -Text 'Back to Reports' -Url '/par-it-internal/reports'
        New-UDGrid -Container -Spacing 2 -AlignItems center -Children {
            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 9 -Children {
                New-UDStack -Direction column -Spacing 1 -Children {
                    New-UDTypography -Text 'Windows devices without a primary user' -Variant h4
                    New-UDTypography -Text 'Shared and kiosk devices may intentionally have no primary user.'
                }
            }
            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 3 -Children {
                New-UDStack -Direction row -JustifyContent flex-end -Children {
                    New-UDButton -Text 'Refresh data' -Variant outlined -ShowLoading -OnClick {
                        $Session:ParAssignmentState = $null
                        Sync-UDElement -Id 'assignment-report'
                    }
                }
            }
        }
        New-UDDynamic -Id 'assignment-report' -LoadingComponent {
            New-UDStack -Direction column -Spacing 2 -Children {
                New-UDTypography -Text 'Loading device assignments and investigation evidence…'
                New-UDProgress
            }
        } -Content {
            if ($null -eq $Session:ParAssignmentState) {
                $Session:ParAssignmentState = New-PITIDeviceAssignmentState
            }
            $state = $Session:ParAssignmentState
            if ($state.Status -eq 'Failed') {
                New-UDAlert -Severity error -Title 'Data could not be loaded' -Text 'A required source failed. Previous results are hidden. Use Refresh data to retry.'
                return
            }
            $snapshot = $state.Snapshot
            New-UDStack -Direction column -Spacing 2 -Children {
                New-UDTypography -Text "Updated $($state.LoadedAt)" -Variant body2
                $investigations = @($snapshot.WithoutPrimaryUser | ForEach-Object { $_.Investigation })
                if ($investigations.Count -eq 0) {
                    New-UDAlert -Severity info -Title 'No results' -Text 'All sources loaded successfully. No Windows devices match the missing-primary-user report.'
                    return
                }
                $rows = @(
                    ConvertTo-PITIDeviceAssignmentRow -Investigation $investigations -SnapshotId $state.SnapshotId
                )
                $columns = @(
                    New-UDTableColumn -Property DeviceName -Title 'Intune device' -IncludeInSearch
                    New-UDTableColumn -Property IntuneDeviceId -Hidden -IncludeInSearch
                    New-UDTableColumn -Property SerialNumber -Title 'Serial number' -IncludeInSearch
                    New-UDTableColumn -Property PrimaryUser -Title 'Intune primary user' -IncludeInSearch -OnRender {
                        New-PITIAssignmentSummary -Name $EventData.PrimaryUserName -Upn $EventData.PrimaryUser -Fallback 'Not recorded'
                    }
                    New-UDTableColumn -Property PrimaryUserId -Hidden -IncludeInSearch
                    New-UDTableColumn -Property CmdbAssignment -Hidden -IncludeInSearch
                    New-UDTableColumn -Property CmdbUserName -Title 'CMDB assigned user' -IncludeInSearch -OnRender {
                        New-PITIAssignmentSummary -Name $EventData.CmdbUserName -Upn $EventData.CmdbUserUpn -Fallback $EventData.CmdbSummary
                    }
                    New-UDTableColumn -Property CmdbUserUpn -Hidden -IncludeInSearch
                    New-UDTableColumn -Property Outcome -Title 'Outcome' -ShowFilter -FilterType select -IncludeInSearch -Options @('Match', 'Mismatch', 'Missing assignment', 'Unresolved')
                    New-UDTableColumn -Property Reason -Hidden -IncludeInSearch
                    New-UDTableColumn -Property RecordNumber -Title 'Investigation' -OnRender {
                        # Use snapshot identity and record position, never a serial or potentially duplicate Intune ID.
                        New-UDButton -Text 'Investigate' -Variant text -OnClick {
                            Show-PITIDeviceInvestigationDialog -State $Session:ParAssignmentState -SnapshotId $EventData.SnapshotId -RecordNumber $EventData.RecordNumber
                        }
                    }
                )
                New-UDTable -Id 'device-records' -Data $rows -Columns $columns -ShowFilter -ShowSearch -ShowPagination -PageSize 10 -PageSizeOptions @(10, 25, 50)
            }
        }
    }
}
