# Security

Satset was built with production security in mind. It includes multiple layers of protection to keep your server safe from malicious clients.

## The Guard

The **Guard** is a token bucket rate limiter that is automatically enabled on the server. It tracks how many packets each player is sending and drops anything that exceeds the limit.

You can configure it during initialization:

```luau
Satset.start({
    guard = {
        maxTokens = 60, -- Max burst capacity
        refillRate = 30, -- Tokens refilled per second
    }
})
```

- **maxTokens**: The maximum number of tokens a player can hold. This allows for small "bursts" of packets.
- **refillRate**: How many tokens are added to the bucket every second.

## Sanitization

All incoming data is sanitized:

- **Type Checking**: Satset ensures that data is read according to the schema. If a client sends a payload that is shorter than expected for a given type, the read operation will fail safely.
- **NaN/Infinity Protection**: All float types (`f32`, `f64`, `Vector3`, `Vector2`, `CFrame`) pass through a sanitization layer that clamps `NaN` and `±Infinity` to `0` on both read and write paths.
- **Bounds Checking**: Satset ensures that buffer reads never exceed the length of the received data.
- **Variable-Length Protection**: Types like `string8`, `string16`, `array`, and `map` validate the declared length prefix against the remaining buffer before reading. A malicious client that sends a length of 255 on a 3-byte buffer will get an empty string instead of a VM crash.

## Listener Protection

All user-registered callbacks (both `Packet:listen` and `Channel:subscribe`) are wrapped in `xpcall`. If your callback throws an error, it will:

1. Be caught and reported via `warn` with the packet/channel name and the error message.
2. Not affect any other listeners registered on the same packet or channel.
3. Not halt the library's internal dispatch loop.

This prevents a single broken game script from taking down the entire networking layer.

## Stateless Design

Because packets are defined with a fixed schema, clients cannot send arbitrary keys or nested tables that might cause memory exhaustion or CPU spikes on the server.
