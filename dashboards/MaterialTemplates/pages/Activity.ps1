New-UDPage -Name 'Activity' -Url '/activity' -AutoInclude -Content {
    New-UDContainer -Children {
        New-UDGrid -Version 2 -Container -JustifyContent center -Children {
            New-UDGrid -Version 2 -Item -ExtraSmallSize 12 -MediumSize 8 -Children {
                New-UDStack -Direction column -Spacing 4 -Children {
                    New-UDStack -Direction column -Spacing 1 -Children {
                        New-UDTypography -Text '06 / ACTIVITY' -Variant overline
                        New-UDTypography -Text 'Keep the work in view.' -Variant h4
                        New-UDTypography -Text 'Refresh a small snapshot without leaving the page.' -Variant body1
                    }
                    $body = New-UDCardBody -Content {
                        New-UDStack -Direction column -Spacing 3 -Children {
                            New-UDTypography -Text 'Workshop snapshot' -Variant h6
                            New-UDDynamic -Id 'material-activity' -Content {
                                # Demonstration delay: replace with your data retrieval.
                                Start-Sleep -Seconds 3
                                $checkedAt = Get-Date -Format 'HH:mm:ss'
                                $summary = 'Three workshop notes are ready to read. One follow-up is waiting for a reply.'

                                New-UDStack -Direction column -Spacing 2 -Children {
                                    New-UDTypography -Text $summary -Variant body1
                                    New-UDTypography -Text "Last checked at $checkedAt" -Variant body2
                                }
                            } -LoadingComponent {
                                New-UDStack -Direction column -Spacing 2 -Children {
                                    New-UDTypography -Text 'Checking the latest activity...' -Variant body1
                                    New-UDProgress
                                    New-UDTypography -Text 'This demonstration takes about three seconds.' -Variant body2
                                }
                            }
                        }
                    }
                    $footer = New-UDCardFooter -Content {
                        New-UDStack -Direction row -Spacing 1 -Children {
                            New-UDButton -Text 'Refresh snapshot' -Variant contained -ShowLoading -OnClick {
                                Sync-UDElement -Id 'material-activity' -Wait -Timeout 10000
                                Show-UDSnackbar -Message 'Snapshot refreshed. You are up to date.' -AnchorVertical bottom -AnchorHorizontal left -AutoHideDuration 5000
                            }
                            New-UDButton -Text 'View summary' -Variant text -OnClick {
                                Show-UDModal -MaxWidth sm -FullWidth -Header {
                                    New-UDTypography -Text 'Workshop summary' -Variant h6
                                } -Content {
                                    New-UDStack -Direction column -Spacing 2 -Children {
                                        New-UDTypography -Text 'Three notes, one useful next step.' -Variant body1
                                        New-UDTypography -Text 'The notes cover the welcome session, shared resources, and ideas for the next workshop. Read them together before choosing what to try.' -Variant body2
                                        New-UDTypography -Text 'This is a fictional snapshot. Closing this summary does not change it.' -Variant body2
                                    }
                                } -Footer {
                                    New-UDButton -Text 'Close' -Variant text -OnClick { Hide-UDModal }
                                }
                            }
                        }
                    }
                    New-UDCard -Body $body -Footer $footer -RemoveMargin
                    New-UDStack -Direction column -Spacing 2 -Children {
                        New-UDTypography -Text 'A gentle reminder' -Variant h6
                        New-UDTypography -Text 'A brief notification can acknowledge something without interrupting the work.' -Variant body1
                        New-UDStack -Direction row -Children {
                            New-UDButton -Text 'Try a reminder' -Variant outlined -OnClick {
                                Show-UDToast -Title 'Workshop reminder' -Message 'Take a moment to read the notes before the next check-in.' -Position bottomRight -Duration 6000 -CloseOnClick -CloseOnEscape
                            }
                        }
                        New-UDTypography -Text 'This shows a sample toast now. It does not schedule a reminder.' -Variant body2
                    }
                    New-UDTypography -Text 'Example activity · The delay is artificial; the snapshot is local filler content.' -Variant caption
                    New-UDStack -Direction row -Children {
                        New-UDButton -Text 'Compare this page in Simple Templates' -Variant text -Size small -Href '/simple-templates/activity' -Target '_blank'
                    }
                }
            }
        }
    }
}
