New-UDPage -Name 'Reports' -Url '/reports' -DefaultHomePage -AutoInclude -Content {
    New-UDTypography -Text 'Reports' -Variant h4

    New-UDGrid -Container -Spacing 2 -Children {
        New-UDGrid -Item -ExtraSmallSize 12 -LargeSize 6 -Children {
            $assignmentHeader = New-UDCardHeader -Title 'Device assignments' -TitleAlignment left -Action (New-UDChip -Label 'Planned')
            $assignmentBody = New-UDCardBody -Content {
                New-UDTypography -Text 'Compare Intune primary users with CMDB assigned users.'
            }
            $assignmentFooter = New-UDCardFooter -Content {
                # New-UDButton -Href needs the app base URL, unlike $Navigation's New-UDListItem -Href and New-UDPage -Url.
                New-UDButton -Text 'Open report' -Variant outlined -Href '/par-it-internal/device-assignments'
            }
            New-UDCard -Header $assignmentHeader -Body $assignmentBody -Footer $assignmentFooter
        }
        New-UDGrid -Item -ExtraSmallSize 12 -LargeSize 6 -Children {
            $missingUserHeader = New-UDCardHeader -Title 'Windows devices without a primary user' -TitleAlignment left -Action (New-UDChip -Label 'Planned')
            $missingUserBody = New-UDCardBody -Content {
                New-UDTypography -Text 'Review missing associations, including intentionally userless devices.'
            }
            New-UDCard -Header $missingUserHeader -Body $missingUserBody
        }
    }
}
