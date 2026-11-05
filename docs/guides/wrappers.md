# Shared wrappers

## Independent ownership with new

`Connex.new(signal)` creates an uncached wrapper. Each wrapper subscribes to the underlying signal lazily when its first listener is added. Choose it when a component owns its lifecycle.

```lua
local wrapper = Connex.new(signal)
wrapper:Connect(function() print("Owned by this component") end)
-- On component teardown, outside callback dispatch:
-- wrapper:Destroy()
```

## Shared ownership with Wrap

`Connex.Wrap(signal)` returns a cached wrapper when one exists. Consumers requiring the same module instance and passing the same signal can share listeners, names, and cleanup effects.

```lua
local first = Connex.Wrap(signal)
first:Connect(function() print("Shared") end, "SharedListener")
local second = Connex.Wrap(signal)
assert(first == second)
```

> **The cache is not permanent**
> It uses weak keys and values. When a wrapper becomes idle, `_checkIdle` removes the signal's cache entry. A later `Wrap` may return a different wrapper even if you still hold the old, reusable object. Cache removal is unconditional: an old or independent wrapper becoming idle can also evict another wrapper's cache entry for the same signal in this version.
>

For shared wrappers, disconnect only the connections your component owns. Reserve `Clean` and `Destroy` for a coordinated owner. Never mutate `Connex.Cache` directly.

## Custom signals

Construction accepts an `RBXScriptSignal` or a table with a function-valued `Connect` member. Connex calls `signal:Connect(callback)` and expects a connection object with `Disconnect` for proper unsubscription. Validation checks only `Connect`; it does not guarantee a custom signal implements the rest of this contract.

---

[Documentation index](../../README.md)
