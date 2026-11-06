# Connect vs ConnectAsync

Both methods register listeners in the same priority-sorted collection. Their callback execution differs.

| Behavior | `Connect` | `ConnectAsync` |
| --- | --- | --- |
| Dispatch | Calls callback through `pcall` | Calls `task.spawn(callback, ...)` |
| Yielding | Can suspend that dispatch's loop | Callback runs in a separate task |
| Priority | Order of inline invocation | Order of calls to `task.spawn` |
| Completion order | A yielding callback delays later listeners in that dispatch | No completion-order guarantee |
| Errors | Failed `pcall` reports via `task.spawn(error, err)` | Reported by the spawned task |

ConnectAsync() schedules callbacks in separate tasks using task.spawn(). Priority determines the scheduling order, but in this case, it does not guarantee the order in which the callbacks complete.

## Keep inline work short

```lua
wrapper:Connect(function(deltaTime)
    updateState(deltaTime)
end, "Update", 100)

wrapper:ConnectAsync(function()
    task.wait(1)
    print("Finished background work")
end, "Background", 0)
```

Here `updateState` is your own non-yielding function. Avoid depending on event ordering across separate firings: yielding inline callbacks can allow overlapping dispatches, and the implementation uses a single processing flag rather than a reentrancy guard.

`Once` creates an inline listener and destroys it before invoking its captured callback. There is no `OnceAsync` method. [Cleanup](cleanup.md) does not cancel tasks already started.

---

[Documentation index](../../README.md)
