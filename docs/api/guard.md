# Guard API

Configuration for server-side rate limiting.

## Configuration Object

```lua
type GuardConfig = {
    maxTokens: number?, -- Max burst capacity (default: 60)
    refillRate: number?, -- Tokens refilled per second (default: 30)
    onFlood: ((player: Player) -> ())?, -- Optional flood callback
}
```

The Guard uses a **Token Bucket** algorithm. Each player has a bucket that starts full with `maxTokens`.

- Every packet sent consumes **1 token**.
- Tokens refill automatically over time at the speed of `refillRate` per second.
- If a player runs out of tokens, any further packets from them are dropped until the bucket has at least 1 token again.

This allows players to send small bursts of traffic without being dropped, while still enforcing a strict average limit.
