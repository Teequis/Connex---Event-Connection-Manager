# Examples

These examples adapt the Connex launch post. Require Connex first:

```lua
local Connex = require(game:GetService("ReplicatedStorage"):WaitForChild("Connex"))
```

## Shared listeners across systems

Each controller below must use the same Connex module instance and the same `Humanoid.Died` signal in the same Luau environment. `Humanoid` is the character's Humanoid, obtained by your controller.

### CharacterController

```lua
local DiedConnex = Connex.Wrap(Humanoid.Died)

DiedConnex:Connect(function()
    print("Character died!")
end, "Character", 100)
```

### InventoryController

```lua
local DiedConnex = Connex.Wrap(Humanoid.Died)

DiedConnex:Connect(function()
    print("Dropping inventory...")
end, "Inventory", 50)
```

### EffectsController

```lua
local DiedConnex = Connex.Wrap(Humanoid.Died)

DiedConnex:Connect(function()
    print("Playing death effects...")
end, "Effects", 10)
```

For these non-yielding callbacks, the event prints:

```text
Character died!
Dropping inventory...
Playing death effects...
```

## Independent wrappers

```lua
local deathBindableEvent = Instance.new("BindableEvent")

local characterConnex = Connex.new(deathBindableEvent.Event)
local movementConnex = Connex.new(deathBindableEvent.Event)

characterConnex:Connect(function()
    print("Character updated!")
end)

movementConnex:Connect(function()
    print("Movement updated!")
end)

movementConnex:Destroy()

deathBindableEvent:Fire()
-- Output: Character updated!

-- At owner teardown, after event callbacks finish:
-- characterConnex:Destroy()
-- deathBindableEvent:Destroy()
```

## Async and one-time listeners

In this example, `signal` is an existing supported signal.

```lua
local wrapper = Connex.new(signal)

wrapper:ConnectAsync(function()
    task.wait(1)
    print("Async completed!")
end)

wrapper:Once(function()
    print("Executed once!")
end)
```

Names and priorities are optional for both methods.

## Pause, resume, priority, and lookup

```lua
local wrapper = Connex.new(signal)

local connection = wrapper:Connect(function()
    print("High priority!")
end, "Main", 100)

connection:Pause()
connection:Resume()
connection:SetPriority(200)

local existing = wrapper:GetConnection("Main")

if existing then
    existing:Disconnect()
end
```

## Wait for event arguments

Schedule the event after registering the waiter. This avoids the launch draft's example waiting forever because nothing fires the BindableEvent.

```lua
local bindableEvent = Instance.new("BindableEvent")
local signalConnex = Connex.new(bindableEvent.Event)

task.delay(1, function()
    bindableEvent:Fire("Ready", 42)
end)

local message, value = signalConnex:Wait()

print(message, value)

-- At owner teardown, outside the event's dispatch:
-- signalConnex:Destroy()
-- bindableEvent:Destroy()
```

## Custom signals

Replace `path.to.Signal` with your custom Signal module. It must provide `Connect` and a returned connection with `Disconnect`; this example also requires `Signal.new` and `Fire`.

```lua
local Signal = require(path.to.Signal)

local mySignal = Signal.new()
local signalConnex = Connex.Wrap(mySignal)

signalConnex:Connect(function(message)
    print(message)
end)

mySignal:Fire("Hello from Signal!")
```

Notice the consistent lowercase `mySignal`. Luau identifiers are case-sensitive.

## Cleanup alternatives

Choose one operation based on ownership. These snippets are alternatives, not a sequence to execute together.

Disconnect only your listener:

```lua
connection:Disconnect()
```

Destroy all listeners but keep the wrapper reusable:

```lua
wrapper:Clean()
```

Permanently destroy an owned wrapper:

```lua
wrapper:Destroy()
```

A shared wrapper can contain other systems' listeners. Prefer disconnecting only your own handle. Do not reuse handles destroyed by `Clean`, `Destroy`, or a fired `Once` listener.

## Character removal with a shared wrapper

`Player` and `Humanoid` are existing references supplied by your character controller. Capture the character instead of reading `Humanoid.Parent` again during removal.

```lua
local character = Humanoid.Parent
local DiedConnex = Connex.Wrap(Humanoid.Died)

local connection = DiedConnex:Connect(function()
    print("Character died!")
end)

local removingConnection

removingConnection = Player.CharacterRemoving:Connect(function(removingCharacter)
    if removingCharacter == character then
        connection:Disconnect()
        removingConnection:Disconnect()
    end
end)
```

This assumes no other owner destroys the shared wrapper or this handle first. If the enclosing controller ends before character removal, it must also disconnect both handles. Idle cleanup does not watch character removal or cancel callbacks already started.

---

[Documentation index](../README.md)
