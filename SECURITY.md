# Security

## Reporting a vulnerability

Report vulnerabilities privately through GitHub: open the repository's
**Security** tab and choose **Report a vulnerability**. Please don't open a public
issue, discussion or pull request for a security problem.

Include what you found, where, how to reproduce it and what an attacker could do
with it. This is a volunteer reference project, so responses are best effort and
there is no guaranteed timeline. Only the `main` branch is maintained.

**In scope:** code and configuration in this repository, and the public
demonstration site.

**Out of scope:** load or denial-of-service testing, automated scanning that
generates heavy traffic, social engineering, and vulnerabilities in third-party
products. Report PowerShell Universal issues to Devolutions and Cloudflare issues
to Cloudflare.

## Public demonstration site

<https://par.ingenite.dev> runs the example apps from this repository so you can
try them. The host has been hardened and only the public apps are reachable, but
availability, privacy and data safety are not guaranteed. Every record in the apps
is synthetic. Don't enter real or personal information into any form.

### Telemetry and privacy

The site collects telemetry for monitoring, analytics and security:

- **The server** records request telemetry: the requested page, method, status
  code, timing and the browser's user-agent string. It does not receive visitors'
  IP addresses, because all traffic reaches it through Cloudflare. Telemetry stays
  on the server and is deleted automatically after a limited retention period.
- **Cloudflare**, which delivers and protects the site, processes connection data
  such as IP addresses to block attacks and limit abusive traffic, under the
  [Cloudflare privacy policy](https://www.cloudflare.com/privacypolicy/).

Personal information, including IP addresses and client details, is never sold,
is not shared with anyone beyond the Cloudflare processing above, and is not used
to identify or track individual visitors. The apps use no advertising or tracking cookies.

Protecting a deployment of your own is your responsibility. The root README
explains why this repository must not be synchronized into a production PSU
server.
