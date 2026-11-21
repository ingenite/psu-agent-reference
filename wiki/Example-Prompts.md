# Example prompts

Agents work best when you tell them to read first and change nothing until you
agree. Each prompt below does that. Give your agent access to the repository, then
paste one in.

## Get an overview

> Explore this project and read its documentation and errata. Explain what the
> PSU instance provides today and how I could use it in my own environment.
> Give me a short overview before making any changes.

## Try the report locally

> Read docs/README.md and docs/errata.md, then inspect the Intune report example
> and its command help. Explain what I can run today, which dependencies I need,
> and what the results mean. Give me the commands to try it locally from the
> repository root. Do not execute them or change files.

## Adapt a feature for your own instance

Replace `<target project>` with the location of your project.

> Read docs/README.md and docs/errata.md. Inspect this repository's Intune
> reporting example and `<target project>`. Propose the smallest adaptation needed
> to use the report there. Identify reusable files, required configuration, and
> verification steps. Distinguish this repository's contributor rules from
> requirements of the reusable example, and follow the target project's own
> instructions. Present the proposal before editing or changing either runtime.

## Why these prompts work

- **"Read the errata"** stops the agent claiming something was verified when it wasn't.
- **"Smallest adaptation"** keeps the agent from bringing over the whole project.
- **"Before editing"** gives you a review point before anything changes.
