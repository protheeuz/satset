# Channels

Channels are for **stateful** synchronization. Unlike packets, which represent an *event*, a channel represents the *state* of an object.

## Delta Compression

Channels only send what has changed. When you update a field in a channel, Satset uses a bitmask to identify only the modified fields and sends only those bytes.

## Definition

```luau
local Satset = require(game:GetService("ReplicatedStorage").Packages.Satset)
local Types = Satset.Types

local PlayerState = Satset.defineChannel({
    name = "PlayerState",
    schema = {
        health = Types.u8,
        mana = Types.u8,
        level = Types.u16,
    },
    unreliable = true,
    resyncInterval = 5
})
```

## Updating State (Server)

```luau
-- Create a stateful entity for a player
local entity = PlayerState:create(player.UserId, {
    health = 100,
    mana = 50,
})

-- Later, updating only health
entity:set("health", 95) -- Only the 1-byte health field is transmitted!
```

## Reading State (Client)

```luau
PlayerState:subscribe(function(entityId, state)
    print("Entity " .. entityId .. " health: " .. state.health)
end)
```

> [!NOTE]
> Channels are optimized for **zero-allocation** updates. When you call `:set()`, Satset writes directly into a pre-allocated buffer and marks a bitmask. No tables are created during the sync process.

## Constraints

- **Fixed-size only**: Channels do not support variable-length types like strings or arrays.
- **32 Field Limit**: Due to the 32-bit bitmask used for dirty tracking, a single channel can have at most 32 fields.
