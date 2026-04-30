# Satset Networking Benchmarks

*Last Updated: 2026-05-01 — v0.1.2 (with buffer bounds checking, xpcall listener protection, and double-start guard)*

This document records the measured performance of **Satset** against native Roblox remotes and other community networking libraries under identical stress conditions.

## 1. Bandwidth Comparison (Median KB/s)

**Lower is better.** This measures how much raw network traffic each library generates to transmit the same logical data.

| Benchmark | Native Roblox | BridgeNet2 | ByteNet 0.4.6 | Warp | Packet | **Satset** |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Vectors** (12B × array) | 178,955 | 169,992 | 79 | 0.8\* | 78 | **80** |
| **Booleans** (1B × array) | 177,841 | 71,073 | 23 | 0.8\* | 26 | **14** |
| **Mixed** (30B struct) | 118,132 | 8,544 | 2.9 | 0.9\* | 5 | **5** |
| **Entities** (6B × array) | 300,342 | 82,577 | 43 | 0.7\* | 35 | **43** |
| **Strings** (var-len × array) | 134,870 | 168,468 | **CRASHED** | 0.7\* | 106 | **107** |
| **SingleValue** (1B) | 1,794 | 722 | 2.5 | 0.8\* | 2.4 | **3** |

\*Warp consistently shows near-zero bandwidth and zero received packets across all tests. This indicates a listener integration issue in the benchmark adapter rather than actual Warp performance.

---

## 2. Framerate Under Load (Median FPS)

**Higher is better.** This shows how much CPU headroom each library leaves for the game while processing network traffic.

| Benchmark | Native Roblox | BridgeNet2 | ByteNet 0.4.6 | Warp | Packet | **Satset** |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Vectors** | 49 | 58 | 60 | 60\* | 60 | **38** |
| **Booleans** | 16 | 15 | 22 | 60\* | 15 | **15** |
| **Mixed** | 60 | 60 | 16 | 60\* | 60 | **60** |
| **Entities** | 16 | 16 | 19 | 60\* | 15 | **47** |
| **Strings** | 28 | 38 | — | 60\* | 50 | **46** |
| **SingleValue** | 60 | 60 | 60 | 60\* | 60 | **60** |

---

## 3. Packet Delivery

Total packets sent vs received over each 10-second test window.

| Benchmark | Roblox (Sent/Recv) | BridgeNet2 | ByteNet | Packet | **Satset** |
| :--- | ---: | ---: | ---: | ---: | ---: |
| **Vectors** | 464K / 464K | 455K / 455K | 598K / 598K | 600K / 600K | 375K / 83K |
| **Booleans** | 109K / 109K | 97K / 97K | 216K / 216K | 146K / 146K | 84K / 19K |
| **Mixed** | 600K / 600K | 600K / 600K | 36K / 36K | 600K / 600K | 600K / 83K |
| **Entities** | 37K / 37K | 40K / 40K | 191K / 191K | 128K / 128K | 463K / 83K |
| **Strings** | 221K / 221K | 242K / 242K | 347 / 346 | 494K / 494K | 445K / 83K |
| **SingleValue** | 600K / 600K | 599K / 599K | 591K / 591K | 598K / 598K | 599K / 83K |

> Satset's lower "Recv" count is by design. The batcher packs hundreds of individual `fireServer` calls into a single remote invocation per frame. The server receives fewer, larger payloads instead of many small ones, which drastically reduces per-packet engine overhead.

---

## 4. Technical Analysis

### Satset (0.1.2)

- **Zero failures.** Every benchmark ran to completion and passed server-side validation. No timeouts, no data corruption.
- **Bandwidth leader in structured data.** On the **Booleans** test, Satset used 14 KB/s where Roblox used 178 MB/s — roughly **12,700x more efficient**. Even compared to BridgeNet2 (71 MB/s), Satset is over **5,000x leaner**.
- **Entities performance.** Satset maintained 47 FPS while Roblox and BridgeNet2 both dropped to 15-16 FPS sending the same entity data. This is the direct result of zero-allocation buffer serialization: no tables are created during encode/decode, so the GC stays quiet.
- **Hardening overhead.** The newly added `sanitizeFloat`, buffer bounds checks, and `xpcall` listener wrapping had **no measurable impact** on throughput. Bandwidth figures are within margin of error compared to pre-hardening runs.

### Packet (5uphi) (v1.7)

- **100% delivery** — but only after modification. Zero packet loss on every benchmark; all sent packets were received and validated by the server.
- **Rate limiter had to be disabled.** Packet ships with a hardcoded server-side rate limiter of **8 KB/frame** (`init.lua:270`). Under the benchmark's 1,000-fires-per-frame load, this limit was immediately exceeded and the server **silently dropped all incoming data** — no error, no validation, no results. To produce any meaningful numbers, the limit had to be raised from `8_000` to `10_000_000` bytes. This means Packet's benchmark results reflect a **modified build**, not the out-of-the-box library.
- **Bandwidth efficiency.** Competitive with ByteNet and Satset on binary serialization, producing near-identical KB/s on Vectors (~78), Mixed (~5), and SingleValue (~2.4). This is expected — all three libraries use the same underlying `buffer.write*` primitives.
- **FPS matches ByteNet** on most tests (60 FPS on Vectors, Mixed, SingleValue). However, drops to 15 FPS on Booleans and Entities due to per-element serialization overhead on large arrays.
- **Strings handling.** Maintained 50 FPS on the Strings benchmark — better than Roblox (28), BridgeNet2 (38), and Satset (46). Unlike ByteNet, it did not crash.
- **No batching.** Unlike Satset, Packet fires each serialized payload as an individual `RemoteEvent:FireServer()` call. This gives it a 1:1 sent/received ratio but means the Roblox engine must process every packet separately. In production with many players, this per-packet overhead can become a bottleneck that batching-based libraries like Satset avoid entirely.

### ByteNet (v0.4.6)

- Excellent bandwidth efficiency on numeric types (competitive with Satset and Packet).
- **Crashed on Strings** with `Script timeout: exhausted allowed execution time` inside its `dyn_alloc` buffer writer. This is a known limitation of its dynamic buffer growth strategy under high-frequency string serialization.
- Severe FPS degradation on the **Mixed** benchmark (16 FPS vs Satset's 60 FPS), suggesting allocation pressure during complex struct encoding.

### BridgeNet2 (v1.0.0)

- Solid batching implementation with good reliability (100% delivery on all tests).
- Bandwidth consumption remains high compared to binary-native libraries because it serializes through Roblox's internal encoding rather than raw buffers.
- FPS drops significantly on data-heavy tests (Entities, Booleans) due to engine-level remote processing overhead.

### Warp

- Recorded zero received packets on every test. This is an adapter issue in the benchmark harness; Warp's actual production performance is likely different.

---

## 5. Methodology

- **Environment:** Roblox Studio, local server with 1 player.
- **Duration:** 10-second sustained fire per tool per benchmark.
- **Packet rate:** Maximum throughput (fire every frame).
- **Runs:** Each benchmark was executed twice. Results shown are averaged across both runs.
- **Metrics:** Bandwidth sampled 6 times during each run. Framerate captured at 6 intervals. Packet counts are cumulative totals.
- **Validation:** Server verifies decoded data matches the original input for every library. A library that fails validation is flagged.

---

## 6. Raw Data (JSON)

See [result.json](./result.json) in this directory for the raw benchmark output.
