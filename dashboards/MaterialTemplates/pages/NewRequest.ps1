New-UDPage -Name 'New request' -Url '/new-request' -AutoInclude -Content {
    New-UDContainer -Children {
        New-UDGrid -Version 2 -Container -JustifyContent center -Children {
            New-UDGrid -Version 2 -Item -ExtraSmallSize 12 -MediumSize 8 -Children {
                New-UDStack -Direction column -Spacing 4 -Children {
                    New-UDStack -Direction column -Spacing 1 -Children {
                        New-UDTypography -Text '03 / NEW REQUEST' -Variant overline
                        New-UDTypography -Text 'Start with a small idea.' -Variant h4
                        New-UDTypography -Text 'Tell us what would make the day a little easier.' -Variant body1
                    }
                    $body = New-UDCardBody -Content {
                        New-UDForm -Id 'material-request' -SubmitText 'Preview request' -ButtonVariant contained -DisableSubmitOnEnter -Children {
                            New-UDStack -Direction column -Spacing 3 -Children {
                                New-UDTypography -Text 'Your idea' -Variant h6
                                New-UDTypography -Text 'One idea per request makes it easier to understand and discuss.' -Variant body2
                                New-UDTextbox -Id 'requestTitle' -Label 'Short title (required)' -HelperText 'A few words that make the idea easy to recognize.' -Variant outlined -FullWidth
                                New-UDTextbox -Id 'requestDescription' -Label 'What would help? (required)' -HelperText 'Describe the outcome you would like, in your own words.' -Variant outlined -Multiline -Rows 3 -FullWidth
                                New-UDSelect -Id 'requestCategory' -Label 'Category' -DefaultValue 'Idea' -Variant outlined -FullWidth -Option {
                                    New-UDSelectOption -Name 'Idea' -Value 'Idea'
                                    New-UDSelectOption -Name 'Question' -Value 'Question'
                                    New-UDSelectOption -Name 'Improvement' -Value 'Improvement'
                                }
                                New-UDTypography -Text 'Add both required fields to enable the preview. This demo shows a summary here; nothing is saved or sent.' -Variant body2
                            }
                        } -OnValidate {
                            if (-not "$($EventData.requestTitle)".Trim() -or -not "$($EventData.requestDescription)".Trim()) {
                                New-UDValidationResult -ValidationError ''
                            }
                            else {
                                New-UDValidationResult -Valid
                            }
                        } -OnSubmit {
                            New-UDStack -Direction column -Spacing 3 -Children {
                                New-UDAlert -Severity success -Title 'Your preview is ready' -Text 'Review the idea below. This demonstration has not saved or sent it.'
                                New-UDTypography -Text $EventData.requestTitle -Variant h6
                                New-UDTypography -Text $EventData.requestDescription -Variant body1
                                New-UDTypography -Text "Category: $($EventData.requestCategory)" -Variant body2
                                New-UDStack -Direction row -Children {
                                    New-UDButton -Text 'Try another request' -Variant text -Href '/material-templates/new-request'
                                }
                            }
                        }
                    }
                    New-UDCard -Body $body -RemoveMargin
                    New-UDStack -Direction row -Children {
                        New-UDButton -Text 'Compare this page in Simple Templates' -Variant text -Size small -Href '/simple-templates/new-request' -Target '_blank'
                    }
                }
            }
        }
    }
}
