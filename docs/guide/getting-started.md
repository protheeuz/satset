# Getting Started

Setting up Satset is straightforward. You need to start the engine on both the server and the client before using it.

## Initialization

In your main server and client scripts:

```luau
local Satset = require(game:GetService("ReplicatedStorage").Packages.Satset)

Satset.start({
    -- Optional configuration
    guard = {
        maxTokens = 60, -- Max burst capacity
        refillRate = 30, -- Tokens refilled per second
    }
})
```

## Your First Packet

Packets are for stateless, fire-and-forget data. Define them in a shared script:

```luau
-- Shared/Packets.luau
local Satset = require(game:GetService("ReplicatedStorage").Packages.Satset)
local Types = Satset.Types

local ChatMessage = Satset.definePacket({
    name = "ChatMessage",
    schema = {
        message = Types.string8,
    }
})

return ChatMessage
```

### Sending a Packet (Client)

```luau
local ChatMessage = require(path.to.Shared.Packets)
ChatMessage:fireServer({ message = "Hello, world!" })
```

### Receiving a Packet (Server)

```luau
local ChatMessage = require(path.to.Shared.Packets)
ChatMessage:listen(function(data, player)
    print(player.Name .. " says: " .. data.message)
end)
```
