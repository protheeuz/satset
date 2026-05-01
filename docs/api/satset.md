# Satset API

The main entry point for the library.

## Functions

### `Satset.start(config: SatsetConfig?)`

Initializes the networking engine. Must be called once on both server and client. Calling it more than once is safe — subsequent calls are ignored with a warning.

- **config**: Optional configuration object.
  - **guard**: Guard configuration (see [Guard API](./guard.md)).

### `Satset.definePacket(config: PacketConfig): Packet`

Defines a new stateless packet.

### `Satset.defineChannel(config: ChannelConfig): Channel`

Defines a new stateful channel.

## Properties

### `Satset.Version`

A string containing the current library version (e.g. `"0.1.3"`).

### `Satset.Types`

Reference to the [Types module](./types.md).

## Performance Context

Initialization and packet definitions are O(1) operations. For details on how Satset's hybrid engine performs under extreme network load, see the [Benchmarks Report](../../benchmark/Benchmarks.md).

## Related Guides

- [Getting Started](../guide/getting-started.md)
- [Installation Guide](../guide/installation.md)
