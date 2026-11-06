New-UDPage -Name 'Overview' -Url '/overview' -DefaultHomePage -AutoInclude -Content {
    $summary = @(
        @{ Label = 'Ready to begin'; Value = '08'; Note = 'A clear next step for each item' }
        @{ Label = 'In progress'; Value = '03'; Note = 'Focused work, moving forward' }
        @{ Label = 'Completed this week'; Value = '12'; Note = 'Small steps adding up' }
    )

    New-UDContainer -Children {
        New-UDStack -Direction column -Spacing 4 -Children {
            New-UDStack -Direction column -Spacing 1 -Children {
                New-UDTypography -Text '01 / OVERVIEW' -Variant overline
                New-UDTypography -Text 'Make room for what matters.' -Variant h4
                New-UDTypography -Text 'A little context, a clear priority, and somewhere to start.' -Variant body1
            }
            $body = New-UDCardBody -Content {
                New-UDStack -Direction column -Spacing 2 -Children {
                    New-UDTypography -Text 'THIS WEEK' -Variant overline
                    New-UDTypography -Text 'Give the welcome kit a fresh start' -Variant h5
                    New-UDTypography -Text 'The outline is ready. Review the remaining work and help the team take the next small step.' -Variant body1
                }
            }
            $footer = New-UDCardFooter -Content {
                New-UDStack -Direction row -Spacing 1 -Children {
                    New-UDButton -Text 'Explore the queue' -Variant contained -Href '/material-templates/work-queue'
                    New-UDButton -Text 'Project review' -Variant text -Href '/material-templates/project-review'
                }
            }
            New-UDCard -Body $body -Footer $footer -RemoveMargin
            New-UDGrid -Version 2 -Container -Spacing 4 -Children {
                foreach ($item in $summary) {
                    New-UDGrid -Version 2 -Item -ExtraSmallSize 12 -MediumSize 4 -Children {
                        New-UDStack -Direction column -Spacing 1 -Children {
                            New-UDTypography -Text $item.Value -Variant h3
                            New-UDTypography -Text $item.Label -Variant subtitle1
                            New-UDTypography -Text $item.Note -Variant body2
                        }
                    }
                }
            }
            New-UDDivider
            New-UDStack -Direction column -Spacing 2 -Children {
                New-UDTypography -Text 'A good place to begin' -Variant h6
                New-UDTypography -Text 'Have an idea? A short request is enough to start a conversation.' -Variant body1
                New-UDStack -Direction row -Children {
                    New-UDButton -Text 'Create a request' -Variant outlined -Href '/material-templates/new-request'
                }
            }
            New-UDStack -Direction column -Spacing 1 -Children {
                New-UDTypography -Text 'Example workspace · All names, counts, and activities are fictional.' -Variant caption
                New-UDStack -Direction row -Children {
                    New-UDButton -Text 'Compare this page in Simple Templates' -Variant text -Size small -Href '/simple-templates/overview' -Target '_blank'
                }
            }
        }
    }
}
