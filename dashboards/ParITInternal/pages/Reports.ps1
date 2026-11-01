New-UDPage -Name 'Reports' -Url '/reports' -DefaultHomePage -AutoInclude -Content {
    New-UDTypography -Text 'Reports' -Variant h4

    New-UDGrid -Container -Spacing 2 -Children {
        New-UDGrid -Item -ExtraSmallSize 12 -LargeSize 6 -Children {
            $assignmentHeader = New-UDCardHeader -Title 'Device assignments' -TitleAlignment left
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
            $missingUserHeader = New-UDCardHeader -Title 'Windows devices without a primary user' -TitleAlignment left
            $missingUserBody = New-UDCardBody -Content {
                New-UDTypography -Text 'Review missing associations, including intentionally userless devices.'
            }
            $missingUserFooter = New-UDCardFooter -Content {
                # Component links include the app base URL, unlike navigation and page URLs.
                New-UDButton -Text 'Open report' -Variant outlined -Href '/par-it-internal/without-primary-user'
            }
            New-UDCard -Header $missingUserHeader -Body $missingUserBody -Footer $missingUserFooter
        }
    }
}
