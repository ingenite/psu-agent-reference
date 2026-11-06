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
            New-UDGrid -Version 2 -Container -Spacing 3 -Children {
                foreach ($item in $summary) {
                    New-UDGrid -Version 2 -Item -ExtraSmallSize 12 -MediumSize 4 -Children {
                        $body = New-UDCardBody -Content {
                            New-UDStack -Direction column -Spacing 1 -Children {
                                New-UDTypography -Text $item.Label -Variant subtitle2
                                New-UDTypography -Text $item.Value -Variant h4
                                New-UDTypography -Text $item.Note -Variant body2
                            }
                        }
                        New-UDCard -Body $body -RemoveMargin
                    }
                }
            }
            New-UDGrid -Version 2 -Container -Spacing 3 -Children {
                New-UDGrid -Version 2 -Item -ExtraSmallSize 12 -MediumSize 8 -Children {
                    $body = New-UDCardBody -Content {
                        New-UDStack -Direction column -Spacing 3 -Children {
                            New-UDStack -Direction row -Children {
                                New-UDChip -Label 'THIS WEEK' -Variant outlined -Color primary -Size small
                            }
                            New-UDStack -Direction column -Spacing 1 -Children {
                                New-UDTypography -Text 'Give the welcome kit a fresh start' -Variant h6
                                New-UDTypography -Text 'The outline is ready. Review the remaining work and help the team take the next small step.' -Variant body1
                            }
                            New-UDStack -Direction row -Spacing 2 -Children {
                                New-UDButton -Text 'Explore the queue' -Variant contained -Href '/simple-templates/work-queue'
                                New-UDButton -Text 'Project review' -Variant text -Href '/simple-templates/project-review'
                            }
                        }
                    }
                    New-UDCard -Body $body -RemoveMargin
                }
                New-UDGrid -Version 2 -Item -ExtraSmallSize 12 -MediumSize 4 -Children {
                    $body = New-UDCardBody -Content {
                        New-UDStack -Direction column -Spacing 2 -Children {
                            New-UDTypography -Text 'A good place to begin' -Variant h6
                            New-UDTypography -Text 'Have an idea? A short request is enough to start a conversation.' -Variant body1
                            New-UDButton -Text 'Create a request' -Variant outlined -Href '/simple-templates/new-request'
                        }
                    }
                    New-UDCard -Body $body -RemoveMargin
                }
            }
            New-UDTypography -Text 'Example workspace · All names, counts, and activities are fictional.' -Variant caption
        }
    }
}
