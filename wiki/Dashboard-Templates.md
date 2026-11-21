# Dashboard templates

Two six-page collections give you a starting layout for common admin pages. They
use the same fictional content, so you can compare the two styles side by side.

| Collection | URL in PSU | Style |
| --- | --- | --- |
| Simple Templates | `/simple-templates` | PSU's native components with a light touch of theming |
| Material Templates | `/material-templates` | Closer to Material Design as implemented by MUI |

Each Material page has a link that opens its Simple counterpart in another tab.

## The six pages, and the problem each solves

| Page | Problem it solves |
| --- | --- |
| Overview | Show the situation at a glance, then make the next action obvious |
| Work queue | Scan, filter and compare many items; open details only when asked |
| New request | Keep a form short, and say what happens after you submit |
| Field guide | Make long guidance scannable; hide exceptions until needed |
| Project review | Separate current status from history |
| Activity | Show that work is running, then confirm when it's done |

The layouts follow two well-known ideas: group related things together, and reveal
detail progressively. They are design examples, not results from user research.

## Why there's no custom CSS or JavaScript

All styling lives in one `$Theme` block per app, and pages use only PSU's
built-in component options. That keeps the templates easy to upgrade with PSU and
easy for an agent to adapt without breaking anything.

## Adapting a page

Ask your agent to copy a page and replace its content. Two PSU details often
catch people out, and the agent should handle both:

- Links inside components include the app's base URL, such as `/simple-templates`.
  If you rename the app, change those links too.
- A new page file doesn't appear until PSU reloads the app declarations.

The Activity page waits three seconds on purpose to imitate slow work; replace the
wait with your real operation.
