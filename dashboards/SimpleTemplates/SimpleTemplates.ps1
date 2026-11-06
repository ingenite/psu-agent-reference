$Navigation = @(
    New-UDListItem -Label 'Overview' -Href '/overview'
    New-UDListItem -Label 'Work queue' -Href '/work-queue'
    New-UDListItem -Label 'New request' -Href '/new-request'
    New-UDListItem -Label 'Field guide' -Href '/field-guide'
    New-UDListItem -Label 'Project review' -Href '/project-review'
    New-UDListItem -Label 'Activity' -Href '/activity'
)

# Owner-approved scope: theme overrides only; pages use native component options.
# Let MUI supply text, status colors, spacing, and component behavior.
$Theme = @{
    light = @{
        palette = @{
            mode = 'light'
            primary = @{ main = '#006B60' }
            background = @{ default = '#F4F6F5' }
        }
    }
    dark = @{
        palette = @{
            mode = 'dark'
            primary = @{ main = '#80D5C7' }
            background = @{ default = '#151515' }
        }
    }
}

foreach ($mode in 'light', 'dark') {
    $Theme[$mode].shape = @{ borderRadius = 10 }
    $Theme[$mode].typography = @{
        h4 = @{ fontWeight = 600 }
        h6 = @{ fontWeight = 600 }
        button = @{ textTransform = 'none' }
    }
    # PSU adapts these theme keys to MUI; use its props/overrides syntax.
    $Theme[$mode].props = @{
        MuiStack = @{ useFlexGap = $true }
    }
    $Theme[$mode].overrides = @{
        MuiContainer = @{ root = @{ paddingTop = '32px'; paddingBottom = '48px' } }
    }
}

$HeaderContent = { New-UDTypography -Text 'Simple Templates' -Variant h6 }
New-UDApp -Title 'Simple Templates' -Navigation $Navigation -Theme $Theme -HeaderContent $HeaderContent -HideUserName
