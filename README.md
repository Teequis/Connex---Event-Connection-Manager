# Connex

A lightweight Luau event connection manager for Roblox. Manage priorities, named listeners, inline or asynchronous callbacks, and shared or independent wrappers.

## Getting Started

- [Introduction](docs/index.md)
- [Installation](docs/getting-started/installation.md)
- [Quick Start](docs/getting-started/quick-start.md)

## Guides

- [Shared vs. Independent Wrappers](docs/guides/wrappers.md)
- [Connect vs. ConnectAsync](docs/guides/execution.md)
- [Priorities & Named Listeners](docs/guides/priorities.md)
- [Cleanup & Best Practices](docs/guides/cleanup.md)
- [Examples](docs/examples.md)

## API Reference

- [Connex](docs/api/Connex.md)
- [ConnexConnection](docs/api/ConnexConnection.md)
- [Benchmarks](docs/benchmarks.md)

## Quick example

Place the Connex ModuleScript in ReplicatedStorage, then require it from your script:

```lua
local Connex = require(game:GetService("ReplicatedStorage"):WaitForChild("Connex"))
local event = Instance.new("BindableEvent")
local wrapper = Connex.new(event.Event)

wrapper:Connect(function(message)
    print(message)
end, "Greeting", 10)

event:Fire("Hello, Connex!")

-- When the owning system shuts down, outside callback dispatch:
-- wrapper:Destroy()
-- event:Destroy()
```

For a shared wrapper, disconnect only the listeners you own. Cleaning or destroying a shared wrapper affects all its consumers.

## Source and license

[Source code](Connex.lua) · [MIT License](LICENSE) · [Documentation maintenance](docs/contributing.md)

## Links

- **Documentation & API Reference:** [Read on GitHub](https://github.com/Teequis/Connex---Event-Connection-Manager/tree/main)
- **Source Code:** [Connex.lua](https://github.com/Teequis/Connex---Event-Connection-Manager/blob/main/Connex.lua)
- **Module:** [Connex in the Creator Store](https://create.roblox.com/store/asset/91608240719237/Connex)

- **Benchmark Place:** [Connex_Benchmark_Place.rbxl (95.8 KB)](https://devforum.roblox.com/secure-uploads/uploads/original/5X/1/c/c/d/1ccd08d6e1e8ddf7b621f73b1a77cc61243eb105.rbxl)
