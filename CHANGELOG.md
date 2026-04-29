# Changelog

All notable changes to Satset will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioned per [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] — 2026-04-30

- **Documentation**: Implementation of `development-patterns.md` and `architecture.md` (df06036) by @protheeuz
- **CI/CD**: Added automatic labeling and first-time contributor welcome workflows (df06036) by @protheeuz

## [0.1.0] — 2026-04-29

This release is the foundation. I've focused on two things: making the serialization fast by avoiding table allocations, and making the network layer "hardened" so clients can't crash the server with bad data. The core feature is the new Channel system, which handles delta-compression by only sending what actually changed.

### Added

- **Serialization Engine**: A zero-allocation buffer pipeline. It avoids the GC overhead common in other libraries. (a0f0f37) by @protheeuz
- **Hybrid Transport**: Stateless packets for events and stateful channels for syncing data over time. (a0f0f37) by @protheeuz
- **Tight Packing**: Added a `u4` type (4-bit) and quantized Vector3/Vector2 types. (a0f0f37) by @protheeuz
- **CFrame Compression**: 18-byte implementation using "smallest-three" reconstruction. (a0f0f37) by @protheeuz
- **Batching**: Bundles all remote calls into a single invocation per frame. (a0f0f37) by @protheeuz
- **Unreliable Protection**: Sequence numbers (u16) on unreliable packets. (a0f0f37) by @protheeuz
- **Benchmark Tool**: An in-Studio harness to compare bandwidth and FPS against ByteNet and native Roblox remotes. (a0f0f37) by @protheeuz

### Changed

- **Hardened Floats**: All float types (f32, f64, Vectors, CFrames) now clamp `NaN` and `Infinity` to `0`. This prevents malicious clients from poisoning server-side physics or math.
- **Rate Limiter API**: Guard now uses `maxTokens` (burst) and `refillRate` (tokens/sec).

### Security

- **Token Bucket**: Server-side rate limiting is enabled by default to prevent packet flooding.
- **Validation**: Every incoming payload is checked against its schema and buffer bounds before processing.
