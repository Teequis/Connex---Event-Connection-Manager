# Quick Start

## Your first listener

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Connex = require(ReplicatedStorage:WaitForChild("Connex"))

local event = Instance.new("BindableEvent")
local wrapper = Connex.new(event.Event)
local connection = wrapper:Connect(function(message)
    print(message)
end, "Greeting", 10)

event:Fire("Hello, Connex!")

-- Later, when the owning system shuts down:
-- wrapper:Destroy()
-- event:Destroy()
```

Read [priorities and names](../guides/priorities.md) next.

---

[Documentation index](../../README.md)
