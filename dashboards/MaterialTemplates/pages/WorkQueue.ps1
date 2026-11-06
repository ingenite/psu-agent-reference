New-UDPage -Name 'Work queue' -Url '/work-queue' -AutoInclude -Content {
    $items = @(
        @{ Title = 'Welcome kit outline'; Owner = 'Alex Morgan'; Status = 'Ready'; Due = 'Nov 09'; Note = 'Agree on the three essentials every new teammate should find first.' }
        @{ Title = 'Workshop agenda'; Owner = 'Sam Rivera'; Status = 'In progress'; Due = 'Nov 10'; Note = 'Leave room between sessions for questions and a short break.' }
        @{ Title = 'Resource library'; Owner = 'Jordan Lee'; Status = 'Needs input'; Due = 'Nov 11'; Note = 'Choose a small set of useful links and confirm who maintains each one.' }
        @{ Title = 'Feedback summary'; Owner = 'Taylor Reed'; Status = 'Ready'; Due = 'Nov 12'; Note = 'Group the feedback into themes before proposing the next experiment.' }
        @{ Title = 'Team introduction'; Owner = 'Alex Morgan'; Status = 'Complete'; Due = 'Nov 13'; Note = 'The introduction is ready for the next welcome session.' }
    )
    $columns = @(
        New-UDTableColumn -Property Title -Title 'Work item' -IncludeInSearch -ShowSort
        New-UDTableColumn -Property Owner -Title 'Owner' -IncludeInSearch -ShowSort
        New-UDTableColumn -Property Status -Title 'Status' -IncludeInSearch -ShowFilter -FilterType select -Options @('Ready', 'In progress', 'Needs input', 'Complete') -OnRender {
            $color = switch ($EventData.Status) {
                'Complete' { 'success' }
                'Needs input' { 'warning' }
                'In progress' { 'primary' }
                default { 'default' }
            }
            New-UDChip -Label $EventData.Status -Color $color -Size small
        }
        New-UDTableColumn -Property Due -Title 'Due' -ShowSort
    )

    New-UDContainer -Children {
        New-UDStack -Direction column -Spacing 4 -Children {
            New-UDStack -Direction column -Spacing 1 -Children {
                New-UDTypography -Text '02 / WORK QUEUE' -Variant overline
                New-UDTypography -Text 'Find the next useful step.' -Variant h4
                New-UDTypography -Text 'Search by item or owner. Filter by status. Expand a row for the brief.' -Variant body1
            }
            $textOptions = New-UDTableTextOption -NoData 'No matching items. Clear the search or choose All in the status filter.'
            New-UDTable -Id 'material-work-queue' -Title 'This week · 5 items' -Data $items -Columns $columns -TextOption $textOptions -Dense -ShowSearch -ShowSort -ShowFilter -OnRowExpand {
                New-UDStack -Direction column -Spacing 1 -Children {
                    New-UDTypography -Text 'THE BRIEF' -Variant overline
                    New-UDTypography -Text $EventData.Note -Variant body1
                }
            }
            New-UDTypography -Text 'Example queue · Status is written out so meaning does not depend on color.' -Variant caption
            New-UDStack -Direction row -Children {
                New-UDButton -Text 'Compare this page in Simple Templates' -Variant text -Size small -Href '/simple-templates/work-queue' -Target '_blank'
            }
        }
    }
}
