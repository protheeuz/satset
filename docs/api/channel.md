# Channel API

Objects returned by `Satset.defineChannel`. Channels are designed for stateful synchronization with delta compression.

## Configuration

```luau
type ChannelConfig = {
    name: string,
    schema: { [string]: any },
    unreliable: boolean?, -- Use UnreliableRemoteEvent (default: true)
    resyncInterval: number?, -- Seconds between full keyframes (default: 5)
}
```

> [!IMPORTANT]
> Channels only support **fixed-size types**. This allows the engine to pre-compute buffer offsets and perform zero-allocation updates.
> There is a limit of **32 fields** per channel. This is a technical constraint of the 32-bit dirty bitmask tracking used to keep delta updates O(1) and extremely compact.

## Methods (Channel Object)

### `:create(entityId: number, initialData: table?): Entity`

**Server Only.** Creates a new stateful entity instance.

- **entityId**: A unique identifier for the entity (e.g., `player.UserId` or a GUID).
- **initialData**: Optional initial state.

### `:subscribe(callback: (entityId: number, state: table) -> ())`

**Client Only.** Registers a listener for state updates. The callback is triggered whenever any field in the entity changes. Subscribers are wrapped in `xpcall`, so an error in one subscriber will not affect others or halt state synchronization.

## Entity Object

Returned by `:create()`. Represents a single stateful instance on the server.

### `:set(fieldName: string, value: any)`

Updates a field. Only this specific field (the delta) will be transmitted to clients in the next frame.

### `:get(fieldName: string): any`

Returns the current value of a field from the local buffer.

### `:getAll(): table`

Returns a dictionary containing the full current state.

### `:destroy()`

Removes the entity and stops synchronization.
