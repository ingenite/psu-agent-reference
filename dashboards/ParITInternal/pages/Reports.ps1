New-UDPage -Name 'Reports' -Url '/reports' -DefaultHomePage -AutoInclude -Content {
    New-UDTypography -Text 'Reports' -Variant h4

    New-UDGrid -Container -Spacing 2 -Children {
        New-UDGrid -Item -ExtraSmallSize 12 -LargeSize 6 -Children {
            New-UDCard -Title 'Device assignments' -Text 'Compare Intune primary users with CMDB assigned users.'
        }
        New-UDGrid -Item -ExtraSmallSize 12 -LargeSize 6 -Children {
            $header = New-UDCardHeader -Title 'Windows devices without a primary user'
            $body = New-UDCardBody -Content {
                New-UDTypography -Text 'Review missing associations, including intentionally userless devices.'
            }
            $footer = New-UDCardFooter -Content {
                New-UDChip -Label 'Planned'
            }
            New-UDCard -Header $header -Body $body -Footer $footer
        }
    }
}
