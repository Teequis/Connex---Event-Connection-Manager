# One signal. An organized set of listeners.

Connex is a small Luau module that manages listeners around Roblox signals. Assign priorities, replace listeners by name, pause individual callbacks, and choose shared or independent ownership.

[Get started](getting-started/quick-start.md){ .md-button .md-button--primary }
[Explore the API](api/Connex.md){ .md-button }

## Choose the behavior you need

| Need | API |
| --- | --- |
| Independent ownership | `Connex.new(signal)` |
| Reuse a cached wrapper | `Connex.Wrap(signal)` |
| Inline callback dispatch | `wrapper:Connect(callback)` |
| Separate callback thread | `wrapper:ConnectAsync(callback)` |
| One event | `wrapper:Once(callback)` |
| Temporarily stop a listener | `connection:Pause()` |
| Release wrapper listeners | `wrapper:Clean()` |

!!! warning "Read the lifecycle guide"
    Cached wrappers share listeners. Cleaning one affects every consumer of that wrapper. Destroyed objects must not be reused. See [cleanup and caveats](guides/cleanup.md).

## Documentation scope

This reference was reviewed against Connex **1.0.0**, source commit [`ab8a3da`](https://github.com/Teequis/Connex---Event-Connection-Manager/blob/ab8a3dae1a4fb0c92ed44a9aef4c385964891bd9/Connex.lua). Examples target Roblox Studio. Runtime behavior is derived from the implementation; the published type annotations have several differences described in the API pages.
