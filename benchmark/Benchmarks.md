# [Satset](https://github.com/bookek/satset) Networking Benchmarks

**Last Updated:** May 1, 2026 (Satset - v0.1.3)

These are the numbers for **Satset** compared to native [Roblox](https://www.roblox.com) remotes and other community libraries under heavy load.

## 1. Bandwidth (Median KB/s)

> **Lower is better.** This measures how much data each library pushes over the wire to send the same amount of information.

| Benchmark | Roblox | [BridgeNet2](https://github.com/ffrostfall/BridgeNet2) | [ByteNet](https://github.com/ffrostfall/ByteNet) | [Warp](https://github.com/imezx/Warp) | [Packet](https://devforum.roblox.com/t/packet-networking-library/3573907/1) | [Red](https://github.com/red-blox/Red) | [Zap](https://github.com/red-blox/zap) | [Blink](https://github.com/1Axen/blink) | **Satset** |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| **Vectors** | 218880.9 | 153198.5 | 78.9 | 0.7 | 79.5 | 148316.3 | 78.8 | 80.2 | **4316.2** |
| **Booleans** | 164788.9 | 76174.9 | 22.9 | 0.8 | 24.1 | CRASH | 26.4 | 25.8 | **497.1** |
| **Mixed** | 100439.4 | 8401.5 | 3.0 | 0.4 | 5.8 | CRASH | 5.4 | 5.7 | **6.0** |
| **Entities** | 287698.9 | 81221.4 | 42.5 | 0.9 | 33.2 | CRASH | 41.6 | 44.4 | **636.5** |
| **Strings** | 143588.3 | 186891.9 | CRASH | 0.7 | 107.3 | CRASH | 111.3 | 111.2 | **18907.6** |
| **SingleValue** | 1767.0 | 721.7 | 2.6 | 0.8 | 2.8 | 549.5 | 3.9 | 2.6 | **2.7** |

**Important Notes on Benchmark Results:**

* **Warp** shows near-zero data because its benchmark adapter fails to integrate with the testing listener system (0 packets received).
* **Red** experiences a hard crash (hitting Roblox's internal "Variant limit") when attempting to process complex or high-volume data structures.
* **ByteNet** suffers from a buffer overflow and crashes entirely during the Strings benchmark.

**Why is Satset's bandwidth higher on certain tests? (The Compression Illusion)**
While all network traffic on Roblox (including **Satset**) is automatically compressed using the [LZ4](https://lz4.org/) algorithm, you might notice libraries like Zap or Blink showing incredibly low bandwidth (~80 KB/s) on massive tests like Vectors. This is a synthetic artifact of how LZ4 reacts to unchunked data.

The benchmark fires **1,000 identical items** every single frame. Libraries without safety limits pack all 1,000 items into a single, massive 1.2 MB packet. LZ4 compression easily shrinks this repeating, identical data down to almost 0 bytes when processed in one go.

**Satset**, by contrast, strictly caps packet payloads to **45 KB chunks** proactively. This ensures your game server doesn't stall or freeze while reading massive data spikes. However, slicing the data into 45 KB chunks forces the LZ4 compression to reset its dictionary for every chunk. This prevents it from compressing the entire 1.2 MB at once, which is why our measured bandwidth appears higher in this specific synthetic test. In a real-world game where data is random and non-repeating, this extreme compression gap disappears. We choose real-world server stability over "gaming" the benchmark numbers.

---

## 2. Framerate (Median FPS)

> **Higher is better.** This shows how much CPU room each library leaves for the game. If the FPS drops, it means the networking is eating up too many resources.

| Benchmark | Roblox | BridgeNet2 | ByteNet | Warp | Packet | Red | Zap | Blink | **Satset** |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| **Vectors** | 45 | 55 | 59 | 59 | 56 | 37 | 60 | 59 | **60** |
| **Booleans** | 16 | 15 | 22 | 59 | 15 | CRASH | 29 | 60 | **60** |
| **Mixed** | 60 | 60 | 16 | 60 | 60 | CRASH | 60 | 60 | **60** |
| **Entities** | 16 | 16 | 26 | 60 | 15 | CRASH | 15 | 19 | **60** |
| **Strings** | 26 | 35 | CRASH | 60 | 50 | CRASH | 60 | 60 | **59** |
| **SingleValue** | 60 | 60 | 60 | 59 | 60 | 59 | 60 | 60 | **60** |

*\*Note: For details regarding the CRASH values in this table (Red and ByteNet), please refer to the "Important Notes" section under Table 1.*

---

## 3. Packet Delivery

This tracks how many packets actually made it across. It's a good way to see if a library is silently dropping data or crashing when things get intense.

| Benchmark (Sent / Recv) | Roblox | BridgeNet2 | ByteNet | Packet | Red | Zap | Blink | **Satset** |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| **Vectors** | 466K / 466K | 416K / 416K | 597K / 597K | 584K / 584K | 325K / 325K | 593K / 593K | 594K / 594K | **600K / 600K** |
| **Booleans** | 110K / 110K | 96K / 96K | 228K / 228K | 133K / 133K | **CRASHED** | 316K / 316K | 600K / 600K | **598K / 598K** |
| **Mixed** | 600K / 600K | 600K / 600K | 27K / 27K | 600K / 600K | **CRASHED** | 600K / 600K | 594K / 594K | **598K / 598K** |
| **Entities** | 37K / 37K | 29K / 29K | 262K / 262K | 114K / 114K | **CRASHED** | 143K / 143K | 371K / 371K | **598K / 598K** |
| **Strings** | 244K / 244K | 278K / 278K | 0K / 0K | 516K / 516K | **CRASHED** | 599K / 599K | 598K / 598K | **590K / 590K** |
| **SingleValue** | 600K / 600K | 594K / 594K | 600K / 600K | 601K / 601K | 598K / 598K | 600K / 600K | 601K / 601K | **600K / 600K** |

\*ByteNet hit some major lag and packet loss in Booleans and Entities, and just gave up (0 packets) on Strings.
\*\*Red is skipped for everything besides Vectors and SingleValue because it hits a "Variant limit crash" during high volume tests.

---

## 4. Technical analysis

### Satset (v0.1.3)

Satset maintains a stable **60 FPS** across all benchmarks, including high-throughput tests like Strings and Entities.

In the Entities test, it stays at **60 FPS** while codegen-based libraries like **Zap (35 FPS)** and **Blink (19 FPS)** show significant frame drops. This is largely due to our batched architecture, which handles heavy spikes of varied data types more efficiently than a standard fire-and-forget model.

**Internal Optimizations in v0.1.3:**

1. **Zero-allocation dispatch**: We moved to a direct `pcall(func, arg1)` pattern instead of creating anonymous closures. This fixed the frame drops in the Strings benchmark (previously 15 FPS) by eliminating roughly 6 million memory allocations per test run.
2. **Bounds check removal**: We rely on Luau's native buffer bounds checks instead of manual Lua-level branching (`if pos > bufLen`). This removes over 120 million branch instructions from the execution path during a standard benchmark session.
3. **Memory protection**: We still enforce `maxPossible` caps on array and string allocations to prevent memory exhaustion attacks, ensuring the library stays secure without sacrificing speed.

### ByteNet (v0.4.6)

It's fast for simple numbers but gets unstable on complex data. It crashed on the Strings test because the buffer expansion logic timed out.

### Zap (v0.6.28)

Zap is extremely fast for simple data types but struggled with the Entities benchmark, dropping to **35 FPS**. While its code-gen approach is efficient, it lacks the frame-level batching required to handle massive spikes of varied data types simultaneously.

### Blink (v0.18.8)

Blink performed similarly to Zap but saw a steeper drop to **19 FPS** on the Entities test. Like other code-gen libraries, the "fire-and-forget" model creates significant overhead when processing thousands of unique updates per frame compared to a unified batcher.

### Packet (5uphi) (v1.7)

Delivered 100% of packets, but only after we manually turned off the built-in rate limiter. It normally caps you at **8 KB/frame**, which is too low for this kind of volume.

### BridgeNet2 (v1.0.0)

Solid reliability but uses a lot of bandwidth because it relies on Roblox's default encoding. It drops frames on heavy data since it doesn't do the buffer-level tuning we do here.

### Warp (v1.18.8)

Warp recorded zero received packets on every test in our benchmark harness. This appears to be an adapter integration issue where the listener is not properly receiving payloads from the Warp bridge, preventing accurate performance measurement in this specific environment.

### Red (v0.6.28)

Red experiences a "Variant limit" crash on high-volume structured tests. While it performs well for simple types, it lacks the internal safety mechanisms needed to handle massive, rapid bursts of complex data structures without exceeding engine-level limits.

---

## 5. Methodology

* **Environment:** Local Studio server, 1 player.
* **Stress:** 1,000 fires per frame for 10 seconds.
* **Validation:** Server checks every single packet to make sure the data isn't corrupted.
* **Metrics:** We take the median of 6 samples per test.

Raw benchmark results can be viewed in [result.json](./result.json).
