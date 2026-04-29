# Changelog

All notable changes to Satset will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioned per [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.2] — 2026-04-30

This update focuses on **Hardening** and **Production Readiness**. We've implemented strict defensive programming to ensure Satset can survive malicious network traffic and internal script errors without crashing the server.

### Added

- **Initialization Guard**: `Satset.start()` now prevents multiple calls, protecting the engine from state corruption.
- **Listener Resilience**: All packet listeners and channel subscribers are now isolated using `xpcall`. An error in one script won't break the entire networking layer.
- **Bounds Checking**: Added strict validation for `string8`, `string16`, `array`, and `map` types to prevent buffer over-reads from malformed packets.
- **CI/CD Automation**: Release workflow now builds and attaches versioned `.rbxm` assets automatically.

### Changed

- **Benchmark Results**: Updated documentation with latest stress-test data showing significant bandwidth and FPS advantages over Roblox and BridgeNet2.
- **Documentation**: Added a detailed Contributor Checklist and updated security guides.

### Fixed

- Resolved type-inference errors and Selene linting warnings in the benchmark harness.
- Fixed a bug where a single failing listener could halt the entire dispatch loop.

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
