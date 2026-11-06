$Navigation = @(
    New-UDListItem -Label 'Overview' -Href '/overview'
    New-UDListItem -Label 'Work queue' -Href '/work-queue'
    New-UDListItem -Label 'New request' -Href '/new-request'
    New-UDListItem -Label 'Field guide' -Href '/field-guide'
    New-UDListItem -Label 'Project review' -Href '/project-review'
    New-UDListItem -Label 'Activity' -Href '/activity'
)

$Theme = @{
    light = @{
        palette = @{
            mode = 'light'
            primary = @{ main = '#1976D2' }
            background = @{ default = '#FAFAFA' }
        }
    }
    dark = @{
        palette = @{
            mode = 'dark'
            primary = @{ main = '#90CAF9' }
            background = @{ default = '#121212' }
        }
    }
}

foreach ($mode in 'light', 'dark') {
    # PSU adapts props/overrides to MUI. Typography, shape, and spacing keep their defaults.
    $Theme[$mode].props = @{
        MuiStack = @{ useFlexGap = $true }
        MuiCard = @{ variant = 'outlined'; elevation = 0 }
    }
    # Owner-approved theme-only CSS: page gutters.
    $Theme[$mode].overrides = @{
        MuiContainer = @{ root = @{ paddingTop = '32px'; paddingBottom = '48px' } }
    }
}

$HeaderContent = { New-UDTypography -Text 'Material Templates' -Variant h6 }
New-UDApp -Title 'Material Templates' -Navigation $Navigation -Theme $Theme -HeaderContent $HeaderContent -HideUserName
