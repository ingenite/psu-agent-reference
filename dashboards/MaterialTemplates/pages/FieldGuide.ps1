New-UDPage -Name 'Field guide' -Url '/field-guide' -AutoInclude -Content {
    $sections = @(
        @{ Title = 'Begin with the outcome'; Text = 'Write down what a useful session would change. A clear outcome helps people decide what to bring and which questions to ask.' }
        @{ Title = 'Make space for different voices'; Text = 'Share a short prompt before the session. Give everyone a moment to think before opening the conversation, and invite written ideas as well as spoken ones.' }
        @{ Title = 'End with one next step'; Text = 'Close by naming one action, one owner, and a time to check back. A small shared commitment is easier to follow than a long list of possibilities.' }
    )

    New-UDContainer -Children {
        New-UDGrid -Version 2 -Container -JustifyContent center -Children {
            New-UDGrid -Version 2 -Item -ExtraSmallSize 12 -MediumSize 8 -Children {
                New-UDStack -Direction column -Spacing 4 -Children {
                    New-UDStack -Direction column -Spacing 1 -Children {
                        New-UDTypography -Text '04 / FIELD GUIDE' -Variant overline
                        New-UDTypography -Text 'A more thoughtful workshop.' -Variant h4
                        New-UDTypography -Text 'A short guide to making time together useful. About 2 minutes to read.' -Variant body1
                    }
                    foreach ($section in $sections) {
                        New-UDStack -Direction column -Spacing 1 -Children {
                            New-UDTypography -Text $section.Title -Variant h6
                            New-UDTypography -Text $section.Text -Variant body1
                        }
                    }
                    New-UDDivider
                    New-UDStack -Direction column -Spacing 1 -Children {
                        New-UDTypography -Text 'Before you invite' -Variant h6
                        New-UDList -Children {
                            New-UDListItem -Label 'One clear outcome' -SubTitle 'What should be different afterward?'
                            New-UDListItem -Label 'A short agenda' -SubTitle 'What needs the group''s attention?'
                            New-UDListItem -Label 'Room to contribute' -SubTitle 'How can everyone share an idea?'
                        }
                    }
                    New-UDStack -Direction column -Spacing 2 -Children {
                        New-UDTypography -Text 'When plans change' -Variant h6
                        New-UDExpansionPanelGroup -Children {
                            New-UDExpansionPanel -Title 'The conversation runs out of time' -Children {
                                New-UDTypography -Text 'Capture the open question, choose someone to follow up, and share a short note afterward. Give the decision the time it needs.' -Variant body1
                            }
                            New-UDExpansionPanel -Title 'The group has different starting points' -Children {
                                New-UDTypography -Text 'Pause for a brief recap. Explain unfamiliar terms and make the shared notes available before moving on.' -Variant body1
                            }
                        }
                    }
                    New-UDStack -Direction row -Children {
                        New-UDButton -Text 'Suggest an improvement' -Variant text -Href '/material-templates/new-request'
                    }
                    New-UDTypography -Text 'Example field notes · Adapt the questions to the people and purpose of your session.' -Variant caption
                    New-UDStack -Direction row -Children {
                        New-UDButton -Text 'Compare this page in Simple Templates' -Variant text -Size small -Href '/simple-templates/field-guide' -Target '_blank'
                    }
                }
            }
        }
    }
}
