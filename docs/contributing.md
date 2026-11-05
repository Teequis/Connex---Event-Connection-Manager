# Documentation maintenance

Documentation is written in GitHub-flavored Markdown and can be read directly in this repository.

Edit the relevant `.md` file and use GitHub's **Preview** tab before committing. Use relative links so pages work both on GitHub and in a local checkout.

Review API descriptions and examples against `Connex.lua` whenever behavior changes. Benchmark results must distinguish author-reported measurements from independently reproduced results.

No website build or Python installation is required to read or edit these pages.

---

[Documentation index](../README.md)

## Source type annotations

At the reviewed commit, `Once` accepts omitted name and priority at runtime, but its source signature uses `name: string, priority: number`. For strict type checking, the source should declare `name: string?, priority: number?`. This documentation describes both parameters as optional. This documentation update does not change Connex.lua.
