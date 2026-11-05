# Priorities & Named Listeners

## Priorities and names

Higher priorities dispatch first; equal priorities preserve registration order. Priority defaults to `0`. Use `connection:SetPriority(value)` to request a resort before a subsequent dispatch.

A name identifies one active listener within a wrapper. Registering the same name disconnects the old listener and emits a warning. Prefer stable names for replaceable tasks; omit names for independent listeners.

```lua
wrapper:Connect(function()
    print("High")
end, "High", 100)

wrapper:Connect(function()
    print("Low")
end, "Low", 0)

local high = wrapper:GetConnection("High")
if high then
    high:SetPriority(200)
end
```

Sorts happen lazily before a later dispatch. SetPriority does not reorder callbacks already being dispatched. For asynchronous listeners, priority orders task spawning, not completion. See [execution behavior](execution.md).

Do not assign Name directly: the wrapper maintains a separate lookup table. Name replacement disconnects the previous handle without destroying it. Listener names are scoped to a wrapper, so shared consumers should agree on naming to avoid collisions.

---

[Documentation index](../../README.md)
