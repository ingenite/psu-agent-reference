# PSU Git setup

## Why manage Git through the API

The project's own rule is: develop in source control, then deploy to PSU by
pulling from Git (ADR-0005). Setting that up by clicking through the admin UI is
hard to repeat and hard to review. Two small scripts call PSU's Management API
instead:

| Script | What it manages |
| --- | --- |
| `tools/Invoke-GitSettingsApi.ps1` | Saved Git configurations: remote, branch, sync behavior, interval |
| `tools/Invoke-SshKeyApi.ps1` | PSU's SSH keys for Git access |

Both need a PSU app token and support `-WhatIf`, so you can preview a change
before it happens.

## Things that surprise people

- **A save replaces the whole configuration.** The API is not a partial update,
  and omitted fields may be reset. Read the existing configuration, change only
  what you need, then save it all back.
- **Saving is not activating.** A saved configuration does nothing until it is
  assigned and applied, and applying replaces repository files on the server.
- **Responses can contain secrets.** Don't log or paste raw output.
- **SSH has extra steps.** You also need to register the public key with GitHub
  as a read-only deploy key, and set up the external Git client for the PSU
  service account. Part of this path is unverified; see the errata.

For a first setup, a public repository over HTTPS with pull-only (`OneWay`) sync
is the simplest path, and it is the one this project's test instance uses. The
root README lists the steps.
