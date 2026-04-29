# Packet API

Objects returned by `Satset.definePacket`.

## Methods

### `:fireServer(data: table)`

**Client Only.** Sends data to the server. Automatically batched.

### `:fireClient(player: Player, data: table)`

**Server Only.** Sends data to a specific player. Automatically batched.

### `:fireAllClients(data: table)`

**Server Only.** Sends data to all players. Automatically batched.

### `:listen(callback: (data: table, sender: Player?) -> ())`

Registers a listener for the packet. Listeners are wrapped in `xpcall` internally, so an error in one listener will not prevent other listeners from running or crash the library. Errors are reported to the output via `warn`.

- **data**: The decoded payload.
- **sender**: The player who sent the packet (Server only).
