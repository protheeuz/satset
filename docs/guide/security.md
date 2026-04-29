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

## Stateless Design

Because packets are defined with a fixed schema, clients cannot send arbitrary keys or nested tables that might cause memory exhaustion or CPU spikes on the server.
