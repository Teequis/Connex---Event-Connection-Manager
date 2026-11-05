# Connex

Returned by `require(ConnexModule)`. Constructors use **dot** syntax; wrapper methods use **colon** syntax. Members prefixed with `_` are internal.

## Constructors

### Connex.new(event) → Connex

Creates an independent wrapper. Accepts an `RBXScriptSignal` or table with a `Connect` function; invalid inputs assert. Does not subscribe until a listener is registered.

```lua
Connex.new(event) -> Connex
```

#### Parameters

| Name | Type | Description |
| --- | --- | --- |
| `event` | `RBXScriptSignal  /  table` | Signal to wrap independently. |

#### Returns

`Connex`

### Connex.Wrap(event) → Connex

Returns the cached wrapper or creates and caches one. See [cache lifetime and shared ownership](../guides/wrappers.md).

```lua
Connex.Wrap(event) -> Connex
```

#### Parameters

| Name | Type | Description |
| --- | --- | --- |
| `event` | `RBXScriptSignal  /  table` | Signal to look up in the shared cache. |

#### Returns

`Connex`

### Connex.Cache

Implementation-visible weak-key, weak-value cache indexed by signal. Treat as internal state; do not modify it.

## Listener registration

### :Connect(callback, name?, priority?) → ConnexConnection

Registers an inline, `pcall`-protected callback. `callback` must be a function or registration asserts. `name` is an optional string; `priority` is an optional number defaulting to `0`. Higher numbers run first; ties use insertion order.

A matching name disconnects the old listener and warns. The old handle is not destroyed by replacement. Returns a [ConnexConnection](ConnexConnection.md).

```lua
:Connect(callback, name?, priority?) -> ConnexConnection
```

#### Parameters

| Name | Type | Description |
| --- | --- | --- |
| `callback` | `(...any) -> ()` | Inline callback protected by pcall. |
| `name` | `string?` | Optional listener name; replaces an existing match. |
| `priority` | `number?` | Higher first; defaults to 0. |

#### Returns

`ConnexConnection`

### :ConnectAsync(callback, name?, priority?) → ConnexConnection

Same registration rules as `Connect`, with callbacks invoked using `task.spawn`. Read [execution semantics](../guides/execution.md) before relying on ordering.

```lua
:ConnectAsync(callback, name?, priority?) -> ConnexConnection
```

#### Parameters

| Name | Type | Description |
| --- | --- | --- |
| `callback` | `(...any) -> ()` | Callback executed with task.spawn. |
| `name` | `string?` | Optional listener name; replaces an existing match. |
| `priority` | `number?` | Higher first; defaults to 0. |

#### Returns

`ConnexConnection`

### :Once(callback, name, priority) → ConnexConnection

Registers a one-time inline callback. Its handle is destroyed **before** callback invocation. Paused listeners do not consume their one invocation; manual `connection:Fire(...)` does.

> **Annotation mismatch**
> The source declares `name: string` and `priority: number` as required here. Runtime registration tolerates nil and defaults priority to zero. For consistency with the declared signature, examples pass an explicit name and priority.
>

```lua
:Once(callback, name, priority) -> ConnexConnection
```

#### Parameters

| Name | Type | Description |
| --- | --- | --- |
| `callback` | `(...any) -> ()` | Callback invoked at most once. |
| `name` | `string` | Listener name (nil is tolerated at runtime). |
| `priority` | `number` | Priority (nil defaults to 0 at runtime). |

#### Returns

`ConnexConnection`

### :Wait() → ...any

Yields the current coroutine and resumes it via `task.spawn` with the next event's arguments. Internally registers an unnamed one-time listener with priority `9999`; this is not an exclusive highest priority. Has no timeout. Cleanup before firing can leave the caller suspended.

The implementation forwards multiple arguments, although its source return annotation is `any`.

```lua
:Wait() -> ...any
```

#### Parameters

None.

#### Returns

`...any`

## Lookup

### :GetConnection(name) → ConnexConnection?

Returns the active named listener, including a paused listener, or nil. Lookup uses a dictionary. The source annotation omits the possible nil return.

```lua
:GetConnection(name) -> ConnexConnection?
```

#### Parameters

| Name | Type | Description |
| --- | --- | --- |
| `name` | `string` | Name of the listener to retrieve. |

#### Returns

`ConnexConnection?`

## Lifecycle

### :Clean() → ()

Destroys listener objects, disconnects the underlying subscription when idle, and removes the cache entry. Wrapper remains reusable. Do not invoke on a shared wrapper unless you own all listeners.

```lua
:Clean() -> ()
```

#### Parameters

None.

#### Returns

`()`

### :Destroy() → ()

Calls `Clean`, clears the wrapper, and removes its metatable. Do not use the object afterward. See [cleanup caveats](../guides/cleanup.md).

```lua
:Destroy() -> ()
```

#### Parameters

None.

#### Returns

`()`

---

[Documentation index](../../README.md)
