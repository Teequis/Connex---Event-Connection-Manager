# Examples

Examples assume `Connex` has been required as shown in [Getting Started](getting-started/quick-start.md). Names and priorities are local to each wrapper.

## Priority and named replacement

```lua
local wrapper = Connex.new(signal)
wrapper:Connect(function() print("High") end, "High", 100)
wrapper:Connect(function() print("Low") end, "Low", 0)
wrapper:Connect(function() print("Replacement") end, "Low", 0)
-- On the next event: High, then Replacement.
local low = wrapper:GetConnection("Low")
if low then
    low:Pause()
    low:SetPriority(50)
    low:Resume()
end
```

## One event or waiting for arguments

```lua
local wrapper = Connex.new(signal)
wrapper:Once(function(value)
    print("First event:", value)
end, "FirstEvent", 0)

-- Run in a coroutine that may yield; signal must fire afterward.
local value = wrapper:Wait()
print("Received:", value)
```

## Character ownership

Capture the character reference when setting up ownership. Keep wrapper teardown outside its own callbacks.

```lua
local function watchCharacter(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    local wrapper = Connex.new(humanoid.Died)
    wrapper:Connect(function()
        print(player.Name, "died")
    end, "Death", 0)

    local removing
    removing = player.CharacterRemoving:Connect(function(removedCharacter)
        if removedCharacter == character then
            wrapper:Destroy()
            removing:Disconnect()
        end
    end)
end
```

Call this function for each character you own. If the enclosing system can end before `CharacterRemoving`, store a separate teardown function and invoke it then too; event-driven cleanup alone is not a complete application lifecycle.
