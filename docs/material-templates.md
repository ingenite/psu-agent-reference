# Material Templates

Material Templates is a separate six-page collection at `/material-templates`.
It keeps the topics, fictional content, and `NN / PAGE` headings from Simple
Templates so you can compare the presentation. Each page has a comparison link
that opens its Simple Templates counterpart in another tab. Match the theme
mode and window width when comparing them. This is a visual comparison, not a
user study.

| Page | What to compare |
| --- | --- |
| Overview | One outlined priority card with actions in its footer; summary numbers sit directly on the canvas. |
| Work queue | Denser table rows and filled status chips. Search, filtering, sorting, and row details remain available. |
| New request | A centered single-column form with guidance beside its fields. |
| Field guide | One centered reading column; the supporting checklist follows the main content. |
| Project review | Tabs share a raised surface; `fullWidth` gives the labels equal space, independently of the content below. |
| Activity | A dynamic snapshot with persistent footer actions, button loading, a summary dialog, and completion snackbar. |

The design references are Material Design as implemented by MUI, and the native
components exposed by PSU. The collection uses MUI's default typography, corner
shape, and 8px spacing scale. A small light/dark theme sets the blue accent,
neutral canvas, outlined cards, flex-gap stacks, and container padding. All CSS
stays in `$Theme` in
`dashboards/MaterialTemplates/MaterialTemplates.ps1`.

The examples apply MUI's [button emphasis](https://mui.com/material-ui/react-button/),
[card content and actions](https://mui.com/material-ui/react-card/), and
[spacing scale](https://mui.com/material-ui/customization/spacing/).
These are design references, not a claim that PSU exposes every option in the
current MUI documentation or implements the latest Material specification.
Use the installed PSU command help and verify the resulting UI when adapting
them. The toast remains a PSU notification example; the snackbar is the
Material-style completion feedback.

Pages keep their data and callbacks locally, without a companion module.
The request form only previews the input. Activity deliberately uses
`Start-Sleep -Seconds 3`; replace it with your retrieval operation when adapting
the page. Its refresh waits for the dynamic region before showing the snackbar.
The sample toast schedules nothing. Internal component links include the app's
base URL, while `$Navigation` links use the page routes.

Project review puts a `New-UDStack -FullWidth` inside `New-UDPaper` so the tab
region keeps its width as the content changes. The Paper lays out its child as
a flex item in this PSU version. `fullWidth` on the tabs distributes the labels;
the surrounding Stack gives the whole region its available width.
