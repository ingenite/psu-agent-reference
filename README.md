# psu-agent-reference

This project builds a full PowerShell Universal (PSU) reference instance **for coding
agents** working on Windows and Microsoft administration tools. The instance is
being developed incrementally. The [documentation index](docs/README.md) provides
setup and reference material, including known limitations. More specific [example prompts](docs/prompts.md)
are available as starting points. Have your agent inspect the source and extract
individual resources for your own implementation.

> [!WARNING]
> **Do not synchronize this repository into a production PSU deployment.**
> Stand up a separate test environment using the steps below, or extract and
> review individual resources for use in your own deployment.

To get started, give your agent access to this repository and ask:

> Explore this project and read its documentation and errata. Explain what the
> PSU instance provides today and how I could use it in my own environment.
> Give me a short overview before making any changes.

When you find something useful:

> Help me adapt this project's implementation of [describe the feature] for my
> own PSU instance. Inspect my environment, identify the requirements, and propose
> the smallest useful change. Wait for my review before editing or deploying.

## Environment

The project's test instance was established with this setup:

1. Install **PowerShell Universal 2026.3.0** from the Windows MSI using all
   defaults: Kestrel, available at `http://localhost:5000`, and a SQLite database.
2. **Optional for this project:** generate a new JWT signing key with
   `tools/New-JwtSigningKey.ps1`. Create or update
   `%ProgramData%\PowerShellUniversal\appsettings.json`, setting `SigningKey`
   inside the `Jwt` object to the generated value. This is the machine-wide
   [app settings override](https://docs.devolutions.net/powershell-universal/config/settings).
3. Configure Git synchronization to `https://github.com/ingenite/psu-agent-reference.git`,
   branch `main`, with pull-only (`OneWay`) behavior and automatic synchronization.
   Confirm the configuration is active, then run a fresh `Show-HelloWorld.ps1`
   job and check its Pipeline Output for `Hello world!`.

Coding agents can work autonomously with the PSU Management API using a PSU
AppToken retrieved through an appropriate PowerShell vault provider.

Use **PowerShell 7.4 or higher**. Module versions in the reference environment:

| Module | Version | Required for |
| --- | --- | --- |
| `Microsoft.Graph.DeviceManagement` | 2.41.2 (exact) | Intune device retrieval and synthetic data tools |
| `Microsoft.Graph.Users` | 2.41.2 (exact) | Entra user retrieval and synthetic data tools |
| `Pester` | 6.1.0 | Repository tests |
| `Microsoft.PowerShell.SecretManagement` | 1.1.2 | Vault-backed AppToken access |
| `Microsoft.PowerShell.SecretStore` | 1.0.6 | Optional local SecretStore example; other vault providers may be used |

Devolutions provides [documentation via MCP](https://docs.devolutions.net/rdm/ribbon-menu-bar/tools/all-tools/mcp-server/access-devolutions-documentation-mcp-server).
Configure Codex with:

```powershell
codex mcp add product-guides-reference --url https://mcp.devolutions.net/docs
```

Repository changes follow [Contributing](CONTRIBUTING.md).
Licensed under the [Mozilla Public License 2.0](LICENSE).
