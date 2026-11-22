$Apps = @(
    @{
        Name = 'PAR IT Internal'
        Href = '/par-it-internal'
        Description = 'Reports that compare synthetic Intune, Entra ID, and CMDB records.'
    }
    @{
        Name = 'Simple Templates'
        Href = '/simple-templates'
        Description = 'Workspace page templates built from native components with light theming.'
    }
    @{
        Name = 'Material Templates'
        Href = '/material-templates'
        Description = 'The same page templates styled with a Material Design theme.'
    }
)

$RepositoryUrl = 'https://github.com/ingenite/psu-agent-reference'

$Content = {
    New-UDContainer -Children {
        New-UDStack -Direction column -Spacing 4 -Children {
            New-UDStack -Direction column -Spacing 1 -Children {
                New-UDTypography -Text 'PowerShell Universal Agent Reference' -Variant h4
                New-UDTypography -Text 'Example apps from a reference PowerShell Universal instance. Every name and record is synthetic.' -Variant body1
            }
            New-UDGrid -Version 2 -Container -Spacing 3 -Children {
                foreach ($app in $Apps) {
                    New-UDGrid -Version 2 -Item -ExtraSmallSize 12 -MediumSize 4 -Children {
                        $body = New-UDCardBody -Content {
                            New-UDStack -Direction column -Spacing 2 -Children {
                                New-UDTypography -Text $app.Name -Variant h6
                                New-UDTypography -Text $app.Description -Variant body2
                                New-UDButton -Text "Open $($app.Name)" -Variant outlined -Href $app.Href
                            }
                        }
                        New-UDCard -Body $body -RemoveMargin
                    }
                }
            }
            New-UDStack -Direction column -Spacing 1 -Children {
                New-UDTypography -Text 'Source, documentation, and agent prompts live in the GitHub project.' -Variant body1
                New-UDStack -Direction row -Children {
                    New-UDButton -Text 'View on GitHub' -Variant contained -Href $RepositoryUrl
                }
            }
        }
    }
}

New-UDApp -Title 'PowerShell Universal Agent Reference' -Content $Content -HideNavigation -HideUserName
