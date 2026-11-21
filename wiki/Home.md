# PSU Agent Reference

This project is a working PowerShell Universal (PSU) instance built **for coding
agents** such as Claude and Codex. It exists because agents copy whatever they find.
Small, tested, idiomatic examples give them better material to copy than scattered
blog snippets.

You don't have to read the code yourself. Point your agent at the repository and
ask it to explain or adapt something. These pages explain what is there and why it
was built that way.

> **Do not synchronize this repository into a production PSU deployment.** Use a
> separate test instance, or extract and review individual resources.

## What's inside

| Page | Why you might care |
| --- | --- |
| [[Example Prompts]] | Copy-paste requests to give your agent |
| [[Device Assignment Reports]] | A realistic Intune, Entra and CMDB investigation app |
| [[Synthetic Data]] | Why all data is fake, and how to change it |
| [[Dashboard Templates]] | Twelve page layouts to start your own apps from |
| [[Design Principles Example]] | Four software-design ideas in one small report |
| [[PSU Git Setup]] | Managing PSU's Git settings and SSH keys through its API |
| [[Benchmark Results]] | Which PSU and database choices actually change performance |

## Where the details live

The [repository](https://github.com/ingenite/psu-agent-reference) is the source
of truth. Command help (`Get-Help <command> -Full`) owns parameters and outputs;
[errata](https://github.com/ingenite/psu-agent-reference/blob/main/docs/errata.md)
lists what has *not* been verified. Read the errata before trusting anything here
in production.
