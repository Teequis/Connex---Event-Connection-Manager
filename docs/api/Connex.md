# Connex

Returned by `require(ConnexModule)`. Constructors use **dot** syntax; wrapper methods use **colon** syntax. Members prefixed with `_` are internal.

## Constructors

### Connex.new(event) → Connex

Creates an independent wrapper. Accepts an `RBXScriptSignal` or table with a `Connect` function; invalid inputs assert. Does not subscribe until a listener is registered.

### Connex.Wrap(event) → Connex

Returns the cached wrapper or creates and caches one. See [cache lifetime and shared ownership](../guides/wrappers.md).

### Connex.Cache

Implementation-visible weak-key, weak-value cache indexed by signal. Treat as internal state; do not modify it.

## Listener registration

### :Connect(callback, name?, priority?) → ConnexConnection

Registers an inline, `pcall`-protected callback. `callback` must be a function or registration asserts. `name` is an optional string; `priority` is an optional number defaulting to `0`. Higher numbers run first; ties use insertion order.

A matching name disconnects the old listener and warns. The old handle is not destroyed by replacement. Returns a [ConnexConnection](ConnexConnection.md).

### :ConnectAsync(callback, name?, priority?) → ConnexConnection

Same registration rules as `Connect`, with callbacks invoked using `task.spawn`. Read [execution semantics](../guides/execution.md) before relying on ordering.

### :Once(callback, name, priority) → ConnexConnection

Registers a one-time inline callback. Its handle is destroyed **before** callback invocation. Paused listeners do not consume their one invocation; manual `connection:Fire(...)` does.

!!! note "Annotation mismatch"
    The source declares `name: string` and `priority: number` as required here. Runtime registration tolerates nil and defaults priority to zero. For consistency with the declared signature, examples pass an explicit name and priority.

### :Wait() → ...any

Yields the current coroutine and resumes it via `task.spawn` with the next event's arguments. Internally registers an unnamed one-time listener with priority `9999`; this is not an exclusive highest priority. Has no timeout. Cleanup before firing can leave the caller suspended.

The implementation forwards multiple arguments, although its source return annotation is `any`.

## Lookup

### :GetConnection(name) → ConnexConnection?

Returns the active named listener, including a paused listener, or nil. Lookup uses a dictionary. The source annotation omits the possible nil return.

## Lifecycle

### :Clean() → ()

Destroys listener objects, disconnects the underlying subscription when idle, and removes the cache entry. Wrapper remains reusable. Do not invoke on a shared wrapper unless you own all listeners.

### :Destroy() → ()

Calls `Clean`, clears the wrapper, and removes its metatable. Do not use the object afterward. See [cleanup caveats](../guides/cleanup.md).
