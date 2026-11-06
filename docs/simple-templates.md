# Simple Templates

Six small PSU pages demonstrate layouts that humans and agents can adapt.
The app is registered in `.universal/dashboards.ps1` at `/simple-templates`.
Its bootstrap, navigation, and theme are in
`dashboards/SimpleTemplates/SimpleTemplates.ps1`; each page owns its content in
the adjacent `pages/` directory. There is no companion module or external data.

| Page file | Building blocks | Design purpose |
| --- | --- | --- |
| `Overview.ps1` | Summary cards, responsive grid, primary and secondary links | Establish context, then make the next action easy to find. |
| `WorkQueue.ps1` | Searchable table, status filter, text chips, expandable rows | Support scanning and comparison; reveal the brief when requested. |
| `NewRequest.ps1` | Grouped fields, helper text, validation, inline preview | Keep the input small and explain what happens next. |
| `FieldGuide.ps1` | Short sections, supporting list, expansion panels | Make headings useful for scanning and keep exceptions out of the main reading flow. |
| `ProjectReview.ps1` | Progress, milestone list, update tab | Separate current state from history while keeping the next step visible. |
| `Activity.ps1` | Dynamic region, loading indicator, summary modal, toast, snackbar | Show work in progress, reveal supporting detail, and acknowledge completion. |

These are examples, not prescriptions for particular business processes. The
content is fictional. The form only renders a preview; it does not save or send
anything. Its preview button becomes available when both required fields contain
text. Reopening the page starts a fresh form.

Activity uses `Start-Sleep -Seconds 3` inside `New-UDDynamic` to simulate work.
Its loading component appears on initial load and refresh. The refresh button
uses `Sync-UDElement -Wait` before showing the completion snackbar. Replace the
delay and local snapshot with your operation when adapting it. The modal reveals
a short summary; the toast is an immediate sample notification and schedules
nothing.

In Project review, the compact tab labels occupy only part of the tab bar, while
the selected tab's content uses the available container width. The introduction
above the milestone list demonstrates this: its text wraps across the content
area rather than being limited to the width of the Milestones label. Keep label
length and content layout separate when adapting the example.

## Adapt a page

Keep the layout and replace the local content. Page paths and `$Navigation` links
are relative to the app; component links such as `New-UDButton -Href` include
`/simple-templates`. Change those links if you change the app's base URL.
Declare new page files with `New-UDPage -AutoInclude`, and add their routes to
`$Navigation` in the bootstrap. Reload the app/page declarations in PSU when
adding a page, then confirm the route opens.

The theme adjusts the primary color, page background, corner radius, heading
weight, button capitalization, and container padding. Stack spacing uses MUI's
native flex gap so it preserves a child grid's margins. Both palettes declare
their MUI `mode` so text and surfaces follow light or dark defaults. All CSS
overrides stay in `$Theme`; pages use native component options. Vertical stacks
declare `-Direction column` because PSU defaults to rows. Cards use an explicit
body to avoid generating an empty header.

The layouts draw on [chunking and meaningful grouping](https://www.nngroup.com/articles/chunking/)
and [progressive disclosure](https://www.nngroup.com/articles/progressive-disclosure/).
These inform the design choices; the examples do not claim measured engagement
or user-study results. PSU's [theme reference](https://docs.devolutions.net/powershell-universal/apps/themes)
describes the underlying theme mechanism.
