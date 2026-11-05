# ConnexConnection

Returned by `Connect`, `ConnectAsync`, and `Once`. It is not separately exported as a runtime constructor. The module exports a Luau type named `ConnexConnection`.

## Properties

| Property | Runtime value | Meaning |
| --- | --- | --- |
| `Name` | `string?` | Optional lookup name; unnamed listeners have nil despite the source's `string` annotation |
| `Priority` | `number` | Higher first; defaults to `0` |
| `Connected` | `boolean` | Active membership; false after `Disconnect` |
| `Enabled` | `boolean` | False while paused |
| `Async` | `boolean` | Callback uses `task.spawn` when true |
| `Once` | `boolean` | Destroyed before the first permitted invocation |

These properties describe live or disconnected handles. After `Destroy` (including `Once` firing or wrapper `Clean`), fields and methods are cleared. Observe state; use methods to change priority or enablement. Do not mutate `Name`, `Connected`, `Async`, or `Once` directly.

## :Fire(...args) → ()

Manually invokes this listener without firing the signal or other listeners. Does nothing if disconnected or paused. Uses the same inline/async and one-time behavior as signal dispatch.

```lua
:Fire(...args) -> ()
```

#### Parameters

| Name | Type | Description |
| --- | --- | --- |
| `...args` | `...any` | Arguments forwarded to this callback. |

#### Returns

`()`

## :SetPriority(newPriority) → ()

Changes priority and marks the wrapper for lazy sorting. Does not reorder a dispatch already underway.

```lua
:SetPriority(newPriority) -> ()
```

#### Parameters

| Name | Type | Description |
| --- | --- | --- |
| `newPriority` | `number` | New dispatch priority. |

#### Returns

`()`

## :Pause() → ()

Sets `Enabled` to false. Preserves registration, name, and the underlying subscription. One-time listeners remain pending.

```lua
:Pause() -> ()
```

#### Parameters

None.

#### Returns

`()`

## :Resume() → ()

Sets `Enabled` to true. Does not reconnect a disconnected listener or replay missed events.

```lua
:Resume() -> ()
```

#### Parameters

None.

#### Returns

`()`

## :Disconnect() → ()

Marks the listener disconnected, clears its callback and named entry, and requests collection cleanup. The last active disconnection unbinds the underlying signal. Repeated calls on an undestroyed handle are harmless. The handle retains a wrapper reference until destroyed or released by its owner.

```lua
:Disconnect() -> ()
```

#### Parameters

None.

#### Returns

`()`

## :Destroy() → ()

Disconnects and clears the table and metatable. Invalidates the handle. Repeated calls are invalid. Never inspect a destroyed one-time handle as though `Connected` were still a boolean.

```lua
:Destroy() -> ()
```

#### Parameters

None.

#### Returns

`()`

---

[Documentation index](../../README.md)
