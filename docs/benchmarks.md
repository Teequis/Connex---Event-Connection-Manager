# Benchmarks

The tables below are **author-reported results** supplied in the Connex launch draft. They have not been rerun or independently verified for the reviewed source commit. The draft reports about five minutes, 51 cycles, 5,796 measurements, zero errors, and roughly 50 samples per configuration in Roblox Studio. Hardware, engine version, and the original benchmark project were not supplied.

The original draft's benchmark download is a placeholder, so there is no working reproduction link yet. The small script later on this page is a separate starting point for measuring **registration and cleanup**; it does not reproduce all reported tables.

## Author-reported measurements

## 1. Connection Creation

Time required to register all listeners.

| Listeners | Native | Connex.Wrap() |
|---|---:|---:|
| 1 | 0.0091 ms | 0.0199 ms |
| 10 | 0.0312 ms | 0.0317 ms |
| 100 | 0.2142 ms | 0.1129 ms |
| 500 | 1.0210 ms | 0.4368 ms |
| 1,000 | 1.9413 ms | 0.9315 ms |

**Connex was approximately 2.08× faster** at creating 1,000 listeners.

## 2. Event Delivery Latency

Time from firing a `BindableEvent` until all listeners finish executing.

| Listeners | Native | Connex.Wrap() |
|---|---:|---:|
| 1 | 76.40 µs | 74.41 µs |
| 10 | 90.88 µs | 79.78 µs |
| 100 | 286.55 µs | 122.91 µs |
| 500 | 1,089.24 µs | 304.54 µs |
| 1,000 | 2,015.04 µs | 541.05 µs |

**Connex delivered 1,000 callbacks approximately 3.72× faster** in this benchmark.

## 3. Fire() Return Time

Time required for `BindableEvent:Fire()` to return, not for all callbacks to complete.

| Listeners | Native | Connex.Wrap() |
|---|---:|---:|
| 1 | 7.20 µs | 6.91 µs |
| 10 | 19.01 µs | 6.97 µs |
| 100 | 87.62 µs | 7.13 µs |
| 500 | 339.57 µs | 7.20 µs |
| 1,000 | 591.94 µs | 7.24 µs |

At 1,000 listeners, Connex reduced the measured `Fire()` return time by **98.8%**, reflecting the difference between scheduling one underlying connection and scheduling 1,000 native connections.

## 4. First Callback Latency

Time between firing the event and starting the first callback.

| Listeners | Native | Connex.Wrap() |
|---|---:|---:|
| 1 | 76.13 µs | 74.15 µs |
| 10 | 76.75 µs | 74.24 µs |
| 100 | 146.71 µs | 78.59 µs |
| 500 | 400.16 µs | 101.27 µs |
| 1,000 | 651.99 µs | 133.64 µs |

Connex reached the first callback approximately **4.88× faster** with 1,000 listeners.

## 5. Connection Cleanup

Time required to disconnect and clean up all listeners.

| Listeners | Native | Connex.Wrap() |
|---|---:|---:|
| 1 | 0.0025 ms | 0.0105 ms |
| 10 | 0.0072 ms | 0.0158 ms |
| 100 | 0.0490 ms | 0.0651 ms |
| 500 | 0.2743 ms | 0.2710 ms |
| 1,000 | 0.5203 ms | 0.5439 ms |

Cleanup performance remained relatively close at higher listener counts. Connex additionally provides centralized lifecycle management through `Clean()` and `Destroy()`.

## 6. Lua Memory Usage

Approximate Lua memory allocation reported by `gcinfo()`.

| Listeners | Native | Connex.Wrap() |
|---|---:|---:|
| 1 | 0.08 KB | 0.98 KB |
| 10 | 1.76 KB | 4.22 KB |
| 100 | 17.54 KB | 34.16 KB |
| 500 | 71.90 KB | 165.02 KB |
| 1,000 | 172.10 KB | 329.34 KB |

**Important:** `gcinfo()` does not fully account for native engine allocations associated with `RBXScriptConnection`.

With 1,000 listeners, the native setup creates 1,000 underlying event connections, while Connex manages the listeners through one.

Connex uses additional Lua objects, so these measurements alone cannot establish which implementation uses less total memory. The 500-listener native memory measurements were also affected by garbage-collection interference.

## 7. Internal Connex Performance

Additional tests measured the overhead of built-in features.

| Operation | 100 listeners | 500 listeners | 1,000 listeners |
|---|---:|---:|---:|
| Priority sorting | 0.0588 ms | 0.3169 ms | 0.7236 ms |
| Named lookups | 0.0373 ms | 0.1840 ms | 0.4036 ms |
| Pause / Resume | 0.0248 ms | 0.1178 ms | 0.2283 ms |

These values represent batches of operations across all listeners, rather than individual method calls.

## 8. Internal Dispatch Throughput

Measured by calling Connex's internal dispatcher directly, excluding the Roblox event scheduler.

| Listeners | Callbacks/sec |
|---|---:|
| 1 | 1,758,144 |
| 10 | 2,770,648 |
| 100 | 2,978,821 |
| 500 | 2,983,865 |
| 1,000 | 2,915,753 |

Connex processed approximately **2.98 million lightweight callbacks per second** with 500 listeners.

This is a synthetic internal throughput test, not a native event-dispatch comparison.

## Reproduce in Studio

Place Connex in `ReplicatedStorage`, then run this in a server Script in an otherwise empty test place. It uses independent wrappers and non-yielding setup. Record Studio/engine version, device, execution mode, listener count, and multiple runs.

```lua
local Connex = require(game:GetService("ReplicatedStorage"):WaitForChild("Connex"))
local COUNT = 1000
local ROUNDS = 10

local function measure(label, register, cleanup)
    local total = 0
    for round = 1, ROUNDS + 1 do
        local event = Instance.new("BindableEvent")
        local start = os.clock()
        local state = register(event.Event)
        cleanup(state)
        local elapsed = os.clock() - start
        event:Destroy()
        if round > 1 then total += elapsed end -- discard warm-up
        task.wait()
    end
    print(label, "mean registration + cleanup ms:", total / ROUNDS * 1000)
end

measure("Native", function(signal)
    local connections = {}
    for i = 1, COUNT do
        connections[i] = signal:Connect(function() end)
    end
    return connections
end, function(connections)
    for _, connection in ipairs(connections) do connection:Disconnect() end
end)

measure("Connex", function(signal)
    local wrapper = Connex.new(signal)
    for i = 1, COUNT do wrapper:Connect(function() end) end
    return wrapper
end, function(wrapper)
    wrapper:Destroy()
end)
```

## Interpret results carefully

The combined measurement includes object allocation and cleanup; it cannot isolate either cost. Run with different listener counts and reverse scenario order to check warm-up bias. Report distributions across independent runs rather than one favorable sample.

For dispatch benchmarks, count completed callbacks and wait for a completion barrier before stopping the timer, especially for `ConnectAsync`. Separate the first dispatch (lazy sorting) from steady state, and vary priority changes, named replacement, callback work, and yielding. A loop timing only `BindableEvent:Fire` can measure scheduling rather than completed listener work.

Fewer native subscriptions do not by themselves prove lower total CPU or memory use. Publish raw scripts and environment details with any results.

---

[Documentation index](../README.md)
