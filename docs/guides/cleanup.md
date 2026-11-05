# Cleanup and caveats

## Choose the appropriate scope

| Operation | Effect | Reuse |
| --- | --- | --- |
| `connection:Disconnect()` | Removes one active listener and clears its callback | Object remains inspectable, but cannot reconnect |
| `connection:Destroy()` | Disconnects, clears table, removes metatable | Never reuse |
| `wrapper:Clean()` | Destroys listeners, unbinds signal, removes cache entry | Wrapper can accept new listeners |
| `wrapper:Destroy()` | Cleans, clears table, removes metatable | Never reuse |

These are alternatives at different scopes, not a required sequence. `Clean` also invalidates any connection handles you retained.

## What automatic cleanup means here

The last disconnection triggers idle cleanup: the underlying signal is disconnected, listener storage is cleared, and the cache entry is removed. A paused listener remains active for this accounting and keeps the wrapper subscribed.

Connex has **no public AutoClean method**, Instance lifecycle watcher, or task-cancellation API. Disconnecting an underlying Roblox signal does not by itself clear all retained Connex objects. Explicitly release listeners when their owner ends.

Callbacks already executing or spawned continue after cleanup. `Wait` can remain suspended indefinitely if its listener is removed before the event arrives. There is no timeout or cancellation result.

## Avoid destructive mutation during dispatch

In this version, destroying a connection can leave a cleared table in the listener array while other listeners remain. The next compaction checks `Connected` through the removed metatable; a nil field is treated as inactive. However, calling wrapper `Clean` or `Destroy` from inside callbacks mutates the collection and processing flag while dispatch is active. Defer wrapper teardown until dispatch has returned, and keep inline callbacks non-yielding when predictable ordering matters.

Do not call methods on an already destroyed connection or wrapper; `Destroy` is not idempotent. Use `Disconnect` for repeated, non-destructive teardown of a live connection handle. Do not call `Disconnect` after `Clean` has destroyed that handle.

Prefer the documented methods to direct property writes. Changing `Name` can desynchronize named lookup, and directly changing `Priority` does not mark the wrapper for sorting.

---

[Documentation index](../../README.md)
