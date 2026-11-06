New-UDPage -Name 'Project review' -Url '/project-review' -AutoInclude -Content {
    $milestones = @(
        @{ Label = 'Discover'; Detail = 'Complete · Gathered the team''s first impressions.' }
        @{ Label = 'Draft'; Detail = 'Complete · Chose the essentials for a first version.' }
        @{ Label = 'Review'; Detail = 'Current · Read through the welcome kit together.' }
        @{ Label = 'Share'; Detail = 'Next · Make the kit available to the next group.' }
    )
    $milestoneIntroduction = 'The welcome kit brings the essentials together so a new teammate can find their way through the first week. We have gathered the first impressions and shaped them into a short draft; the next step is to check that the guidance feels clear and welcoming. Use the milestones below to see what is complete and where a little attention will help us move forward.'
    $updates = @(
        @{ When = 'Today'; Title = 'The first draft is ready'; Text = 'Alex shared a short version for the team to review.' }
        @{ When = 'Yesterday'; Title = 'The outline came together'; Text = 'Sam grouped the ideas into three useful sections.' }
        @{ When = 'Monday'; Title = 'A shared starting point'; Text = 'The team agreed on a smaller, more welcoming first edition.' }
    )

    New-UDContainer -Children {
        New-UDStack -Direction column -Spacing 4 -Children {
            New-UDStack -Direction column -Spacing 1 -Children {
                New-UDTypography -Text '05 / PROJECT REVIEW' -Variant overline
                New-UDTypography -Text 'The welcome kit is taking shape.' -Variant h4
                New-UDTypography -Text 'A shared view of where we are and what comes next.' -Variant body1
            }
            New-UDGrid -Version 2 -Container -Spacing 3 -Children {
                New-UDGrid -Version 2 -Item -ExtraSmallSize 12 -MediumSize 8 -Children {
                    $body = New-UDCardBody -Content {
                        New-UDStack -Direction column -Spacing 3 -Children {
                            New-UDStack -Direction row -Children {
                                New-UDChip -Label 'Ready for review' -Color primary -Variant outlined -Size small
                            }
                            New-UDTypography -Text '2 of 4 milestones complete' -Variant h6
                            New-UDProgress -PercentComplete 50
                            New-UDTypography -Text 'Next: read the draft together and agree on the final changes.' -Variant body1
                        }
                    }
                    New-UDCard -Body $body -RemoveMargin
                }
                New-UDGrid -Version 2 -Item -ExtraSmallSize 12 -MediumSize 4 -Children {
                    New-UDStack -Direction column -Spacing 2 -Children {
                        New-UDTypography -Text 'At a glance' -Variant h6
                        New-UDTypography -Text 'Coordinator · Alex Morgan' -Variant body2
                        New-UDTypography -Text 'Next check-in · Thursday, 10:00' -Variant body2
                        New-UDButton -Text 'Read the field guide' -Variant outlined -Href '/simple-templates/field-guide'
                    }
                }
            }
            New-UDTabs -Id 'template-review-tabs' -Tabs {
                New-UDTab -Text 'Milestones' -Content {
                    New-UDContainer -Children {
                        New-UDStack -Direction column -Spacing 2 -Children {
                            New-UDTypography -Text $milestoneIntroduction -Variant body1
                            New-UDList -Children {
                                foreach ($milestone in $milestones) {
                                    New-UDListItem -Label $milestone.Label -SubTitle $milestone.Detail
                                }
                            }
                        }
                    }
                }
                New-UDTab -Text 'Recent updates' -Content {
                    New-UDStack -Direction column -Spacing 3 -Children {
                        foreach ($update in $updates) {
                            New-UDStack -Direction column -Spacing 1 -Children {
                                New-UDTypography -Text $update.When -Variant overline
                                New-UDTypography -Text $update.Title -Variant h6
                                New-UDTypography -Text $update.Text -Variant body1
                            }
                        }
                    }
                }
            }
            New-UDTypography -Text 'Example project · Progress reflects completed milestones, not time remaining.' -Variant caption
        }
    }
}
