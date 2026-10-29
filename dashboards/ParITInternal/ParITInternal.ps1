$Navigation = @(
    New-UDListItem -Label 'Reports' -Href '/reports'
)

$HeaderContent = {
    New-UDStack -Direction row -Spacing 2 -AlignItems center -Children {
        New-UDTypography -Text 'PAR IT Internal'
        New-UDTypography -Text 'Demo · Synthetic data'
    }
}

New-UDApp -Title 'PAR IT Internal' -Navigation $Navigation -HeaderContent $HeaderContent
