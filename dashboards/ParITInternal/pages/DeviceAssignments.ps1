New-UDPage -Name 'Device assignments' -Url '/device-assignments' -AutoInclude -Content {
    New-UDTypography -Text 'Device assignments' -Variant h4
    New-UDTypography -Text 'Compare Intune primary users with CMDB assigned users.'
    New-UDTypography -Text 'Report content is planned and is not available yet.'
    New-UDLink -Text 'Back to Reports' -Url '/reports'
}
