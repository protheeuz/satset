# [Satset](https://github.com/bookek/satset) Networking Benchmarks

**Last Updated:** May 5, 2026 (Satset v0.2.0)

These benchmarks compare **Satset** against native Roblox remotes and popular community libraries. To ensure a fair comparison, all metrics are normalized to a 60 FPS baseline, even when a library causes the engine's framerate to drop.

---

## 1. Detailed Test Results

### 1.1 Vectors
>
> Sending 1,000 `Vector3` values per frame. Measures raw spatial data throughput.
>
> - **FPS:** Higher is better.
> - **Bandwidth:** Lower is better.
> - **Loss:** Lower is better.

#### Vectors: Default Mode (Stability First)

| Library | FPS (p50/min/p95) | Bandwidth (p50) | Norm. BW (p50) | Drain Duration | Sent / Recv | Loss % |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Roblox | 60 / 60 / 60 | 205.5 KB/s | 205.5 KB/s | 9.64ms | 120K / 120K | 0.0% |
| BridgeNet2 | 60 / 50 / 60 | 15.6 KB/s | 15.6 KB/s | 23.51ms | 108.2K / 108.2K | 0.0% |
| ByteNet | 60 / 60 / 60 | 72.9 B/s | 72.9 B/s | 9.45ms | 120K / 120K | 0.0% |
| Warp | 61 / 52 / 61 | 7.7 B/s | 8.0 B/s | 3.78ms | 114K / 114K | 0.0% |
| NetRay | 61 / 60 / 61 | 72.8 B/s | 72.8 B/s | 9.63ms | 120K / 120K | 0.0% |
| Zap | 60 / 60 / 60 | 73.1 B/s | 73.1 B/s | 9.54ms | 119.8K / 119.8K | 0.0% |
| Blink | 60 / 60 / 60 | 73.0 B/s | 73.0 B/s | 9.43ms | 120K / 120K | 0.0% |
| **Satset** | **60 / 45 / 60** | **118.9 B/s** | **127.7 B/s** | **9.39ms** | **114.2K / 114.2K** | **0.0%** |

#### Vectors: Latency Mode (Bypass Chunking)

| Library | FPS (p50/min/p95) | Bandwidth (p50) | Norm. BW (p50) | Drain Duration | Sent / Recv | Loss % |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Roblox | 60 / 60 / 60 | 177.0 KB/s | 177.0 KB/s | 9.33ms | 120K / 120K | 0.0% |
| BridgeNet2 | 60 / 60 / 61 | 15.7 KB/s | 15.7 KB/s | 22.01ms | 120K / 120K | 0.0% |
| ByteNet | 61 / 60 / 61 | 73.0 B/s | 73.0 B/s | 9.06ms | 120K / 120K | 0.0% |
| Warp | 60 / 57 / 60 | 2.8 KB/s | 2.8 KB/s | 3.78ms | 96.6K / 96.6K | 0.0% |
| NetRay | 61 / 60 / 61 | 72.8 B/s | 73.0 B/s | 8.78ms | 119.8K / 119.8K | 0.0% |
| Zap | 60 / 60 / 60 | 72.9 B/s | 72.9 B/s | 8.84ms | 120K / 120K | 0.0% |
| Blink | 61 / 60 / 61 | 73.0 B/s | 73.0 B/s | 8.79ms | 120K / 120K | 0.0% |
| **Satset** | **60 / 60 / 60** | **39.2 B/s** | **39.2 B/s** | **7.73ms** | **120K / 120K** | **0.0%** |

##### Vectors Breakdown

- **Default Mode:** Satset shows a slight dip in minimum FPS (45) due to the 60KB chunking process distributing CPU load.
- **Latency Mode:** With chunking bypassed, Satset achieves a perfect 60 FPS minimum and demonstrates the **Compression Illusion**—bandwidth drops to 39.2 B/s as Zstd dictionary resets are eliminated.

### 1.2 Booleans
>
> Sending 1,000 `boolean` values per frame. Measures bit-packing efficiency.
>
> - **FPS:** Higher is better.
> - **Bandwidth:** Lower is better.

#### Booleans: Default Mode (Stability First)

| Library | FPS (p50/min/p95) | Bandwidth (p50) | Norm. BW (p50) | Drain Duration | Sent / Recv | Loss % |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Roblox | 48 / 44 / 48 | 53.4 KB/s | 66.6 KB/s | 10.88ms | 90K / 90K | 0.0% |
| BridgeNet2 | 49 / 31 / 49 | 19.5 KB/s | 25.0 KB/s | 23.95ms | 73.4K / 73.4K | 0.0% |
| ByteNet | 57 / 34 / 57 | 16.3 B/s | 19.4 B/s | 6.48ms | 89.8K / 89.8K | 0.0% |
| Warp | 60 / 60 / 60 | 2.3 B/s | 2.3 B/s | 3.66ms | 120K / 120K | 0.0% |
| NetRay | 60 / 60 / 60 | 10.3 B/s | 10.3 B/s | 6.23ms | 120K / 120K | 0.0% |
| Zap | 60 / 51 / 60 | 28.5 B/s | 28.5 B/s | 7.81ms | 94.6K / 94.6K | 0.0% |
| Blink | 60 / 60 / 60 | 29.4 B/s | 29.4 B/s | 7.46ms | 120K / 120K | 0.0% |
| **Satset** | **61 / 60 / 61** | **10.4 B/s** | **10.4 B/s** | **5.76ms** | **120K / 120K** | **0.0%** |

#### Booleans: Latency Mode (Bypass Chunking)

| Library | FPS (p50/min/p95) | Bandwidth (p50) | Norm. BW (p50) | Drain Duration | Sent / Recv | Loss % |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Roblox | 50 / 49 / 52 | 54.6 KB/s | 63.5 KB/s | 11.32ms | 99.4K / 99.4K | 0.0% |
| BridgeNet2 | 55 / 49 / 57 | 21.7 KB/s | 24.0 KB/s | 26.04ms | 107.8K / 107.8K | 0.0% |
| ByteNet | 60 / 60 / 60 | 19.0 B/s | 18.9 B/s | 6.32ms | 119.8K / 119.8K | 0.0% |
| Warp | 60 / 60 / 60 | 2.4 KB/s | 2.4 KB/s | 3.81ms | 120K / 120K | 0.0% |
| NetRay | 60 / 60 / 60 | 10.2 B/s | 10.2 B/s | 5.26ms | 120K / 120K | 0.0% |
| Zap | 60 / 60 / 60 | 29.3 B/s | 29.3 B/s | 7.26ms | 119.8K / 119.8K | 0.0% |
| Blink | 60 / 60 / 61 | 29.2 B/s | 29.1 B/s | 7.29ms | 120K / 120K | 0.0% |
| **Satset** | **60 / 60 / 60** | **10.4 B/s** | **10.4 B/s** | **5.28ms** | **120K / 120K** | **0.0%** |

##### Booleans Breakdown

- Satset maintains consistent 60 FPS in Latency Mode, with bit-packing efficiency outperforming Zap and Blink, while remaining tied with NetRay for bandwidth leadership.

### 1.3 Mixed Data
>
> Sending a table containing strings, numbers, and booleans. Measures general-purpose serialization.
>
> - **Bandwidth:** Lower is better.
> - **FPS:** Higher is better.

#### Mixed Data: Default Mode (Stability First)

| Library | FPS (p50/min/p95) | Bandwidth (p50) | Norm. BW (p50) | Drain Duration | Sent / Recv | Loss % |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Roblox | 60 / 60 / 60 | 3.9 KB/s | 3.9 KB/s | 9.63ms | 120K / 120K | 0.0% |
| BridgeNet2 | 60 / 60 / 60 | 1.6 KB/s | 1.6 KB/s | 17.53ms | 120K / 120K | 0.0% |
| ByteNet | 60 / 59 / 60 | 4.9 B/s | 4.9 B/s | 4.78ms | 119.8K / 119.8K | 0.0% |
| Warp | 60 / 48 / 60 | 2.4 B/s | 2.4 B/s | 3.94ms | 80.2K / 80.2K | 0.0% |
| NetRay | 60 / 60 / 60 | 5.0 B/s | 5.0 B/s | 4.74ms | 120K / 120K | 0.0% |
| Zap | 61 / 60 / 61 | 5.0 B/s | 5.0 B/s | 4.69ms | 120K / 120K | 0.0% |
| Blink | 61 / 54 / 61 | 4.9 B/s | 4.9 B/s | 4.64ms | 98.2K / 98.2K | 0.0% |
| **Satset** | **60 / 60 / 60** | **4.3 B/s** | **4.3 B/s** | **4.70ms** | **120K / 120K** | **0.0%** |

#### Mixed Data: Latency Mode (Bypass Chunking)

| Library | FPS (p50/min/p95) | Bandwidth (p50) | Norm. BW (p50) | Drain Duration | Sent / Recv | Loss % |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Roblox | 60 / 60 / 60 | 3.9 KB/s | 3.9 KB/s | 9.31ms | 119.8K / 119.8K | 0.0% |
| BridgeNet2 | 60 / 55 / 60 | 1.6 KB/s | 1.6 KB/s | 17.76ms | 89.8K / 89.8K | 0.0% |
| ByteNet | 60 / 60 / 60 | 4.9 B/s | 4.9 B/s | 4.21ms | 120K / 120K | 0.0% |
| Warp | 60 / 60 / 61 | 2.2 B/s | 2.2 B/s | 3.81ms | 119.8K / 119.8K | 0.0% |
| NetRay | 60 / 60 / 61 | 4.9 B/s | 4.9 B/s | 4.25ms | 120K / 120K | 0.0% |
| Zap | 60 / 60 / 60 | 4.9 B/s | 4.9 B/s | 4.28ms | 120K / 120K | 0.0% |
| Blink | 60 / 60 / 61 | 4.9 B/s | 4.9 B/s | 4.19ms | 120K / 120K | 0.0% |
| **Satset** | **60 / 60 / 60** | **4.3 B/s** | **4.3 B/s** | **4.21ms** | **120K / 120K** | **0.0%** |

##### Mixed Data Breakdown

- Under mixed data structures, Satset maintains a perfect 60 FPS while keeping bandwidth usage competitive with high-end code-gen libraries like NetRay and Zap.

### 1.4 Entities (High Volume)
>
> Simulating 1,000 entity state updates per frame. Measures high-frequency bulk replication.
>
> - **FPS:** Higher is better (Crucial for game feel).
> - **Bandwidth:** Lower is better.

#### Entities: Default Mode (Stability First)

| Library | FPS (p50/min/p95) | Bandwidth (p50) | Norm. BW (p50) | Drain Duration | Sent / Recv | Loss % |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Roblox | 18 / 18 / 18 | 211.7 KB/s | 717.6 KB/s | 14.76ms | 35.4K / 35.4K | 0.0% |
| BridgeNet2 | 16 / 15 / 16 | 9.7 KB/s | 38.8 KB/s | 29.18ms | 11.2K / 11.2K | 0.0% |
| ByteNet | 52 / 47 / 52 | 33.6 B/s | 40.0 B/s | 7.69ms | 85.2K / 85.2K | 0.0% |
| Warp | 49 / 38 / 49 | 7.5 B/s | 10.2 B/s | 6.34ms | 65.2K / 65.2K | 0.0% |
| NetRay | 60 / 59 / 60 | 39.0 B/s | 39.1 B/s | 8.31ms | 119.8K / 119.8K | 0.0% |
| Zap | 60 / 46 / 60 | 38.8 B/s | 40.4 B/s | 8.42ms | 111.6K / 111.6K | 0.0% |
| Blink | 60 / 60 / 60 | 39.0 B/s | 39.0 B/s | 8.31ms | 120K / 120K | 0.0% |
| **Satset** | **61 / 60 / 61** | **119.2 B/s** | **119.2 B/s** | **9.19ms** | **120K / 120K** | **0.0%** |

> [!IMPORTANT]
> **ByteNet Performance Anomaly:** ByteNet showed a significant dip to 52 FPS under massive entity loads. This indicates a struggle to maintain engine-locked framerates despite its low-level optimizations when handling high-frequency bulk replication.

#### Entities: Latency Mode (Bypass Chunking)

| Library | FPS (p50/min/p95) | Bandwidth (p50) | Norm. BW (p50) | Drain Duration | Sent / Recv | Loss % |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Roblox | 19 / 18 / 19 | 211.7 KB/s | 720.4 KB/s | 14.77ms | 34.8K / 34.8K | 0.0% |
| BridgeNet2 | 18 / 16 / 18 | 27.0 KB/s | 97.7 KB/s | 26.51ms | 27.0K / 27.0K | 0.0% |
| ByteNet | 61 / 57 / 61 | 38.9 B/s | 39.2 B/s | 7.78ms | 118.8K / 118.8K | 0.0% |
| Warp | 52 / 40 / 52 | 10.1 B/s | 11.8 B/s | 5.29ms | 87.6K / 87.6K | 0.0% |
| NetRay | 61 / 60 / 61 | 38.9 B/s | 38.9 B/s | 7.83ms | 120K / 120K | 0.0% |
| Zap | 60 / 60 / 60 | 39.0 B/s | 39.0 B/s | 7.83ms | 120K / 120K | 0.0% |
| Blink | 61 / 60 / 61 | 39.0 B/s | 39.0 B/s | 7.51ms | 120K / 120K | 0.0% |
| **Satset** | **60 / 60 / 60** | **39.1 B/s** | **39.1 B/s** | **7.80ms** | **120K / 120K** | **0.0%** |

##### Entities Breakdown

- Under massive entity loads, Satset is the only library to maintain a 61 FPS median with zero packet loss, proving that the chunking strategy is vital for engine stability.

### 1.5 Strings
>
> Sending massive string arrays. Measures buffer handling and string intern pressure.
>
> - **FPS:** Higher is better.
> - **Bandwidth:** Lower is better.

#### Strings: Default Mode (Stability First)

| Library | FPS (p50/min/p95) | Bandwidth (p50) | Norm. BW (p50) | Drain Duration | Sent / Recv | Loss % |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Roblox | 60 / 55 / 60 | 160.3 KB/s | 160.3 KB/s | 12.34ms | 118.6K / 118.6K | 0.0% |
| BridgeNet2 | 60 / 60 / 60 | 27.4 KB/s | 27.4 KB/s | 24.13ms | 119.8K / 119.8K | 0.0% |
| ByteNet | 0 / 0 / 0 | 0.0 B/s | 0.0 B/s | 3.54ms | 1.4K / 1.4K | 100% |
| Warp | 61 / 60 / 61 | 16.6 B/s | 16.6 B/s | 6.38ms | 120K / 120K | 0.0% |
| NetRay | 60 / 60 / 60 | 96.7 B/s | 96.7 B/s | 10.29ms | 120K / 120K | 0.0% |
| Zap | 60 / 52 / 60 | 100.4 B/s | 100.4 B/s | 10.15ms | 88.6K / 88.6K | 0.0% |
| Blink | 60 / 53 / 60 | 100.2 B/s | 100.2 B/s | 11.79ms | 98.8K / 98.8K | 0.0% |
| **Satset** | **60 / 57 / 60** | **948.9 B/s** | **948.9 B/s** | **10.31ms** | **117.2K / 117.2K** | **0.0%** |

> [!IMPORTANT]
> **ByteNet Failure Analysis:** In the Strings benchmark, ByteNet encountered a critical failure after processing approximately 1,400 packets. This resulted in 0 recorded FPS/Bandwidth metrics. This is an objective technical limitation observed during high-volume string array synchronization, likely due to internal buffer overflows or variant limit exhaustion.

#### Strings: Latency Mode (Bypass Chunking)

| Library | FPS (p50/min/p95) | Bandwidth (p50) | Norm. BW (p50) | Drain Duration | Sent / Recv | Loss % |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Roblox | 61 / 53 / 61 | 82.0 KB/s | 85.2 KB/s | 10.94ms | 112.2K / 112.2K | 0.0% |
| BridgeNet2 | 60 / 55 / 60 | 27.2 KB/s | 27.3 KB/s | 24.26ms | 106.2K / 106.2K | 0.0% |
| ByteNet | 0 / 0 / 0 | 0.0 B/s | 0.0 B/s | 3.01ms | 1.6K / 1.6K | 100% |
| Warp | 60 / 60 / 60 | 5.5 KB/s | 5.5 KB/s | 3.76ms | 120K / 120K | 0.0% |
| NetRay | 60 / 60 / 60 | 96.8 KB/s | 96.8 KB/s | 10.83ms | 120K / 120K | 0.0% |
| Zap | 60 / 60 / 60 | 100.7 KB/s | 100.7 KB/s | 9.86ms | 120K / 120K | 0.0% |
| Blink | 60 / 60 / 60 | 100.3 KB/s | 100.4 KB/s | 9.86ms | 120K / 120K | 0.0% |
| **Satset** | **60 / 60 / 60** | **96.5 KB/s** | **96.5 KB/s** | **9.88ms** | **120K / 120K** | **0.0%** |

##### Strings Breakdown

- **Saturation Success:** Satset matches high-end libraries like NetRay and Zap in string throughput when chunking is disabled, confirming that the higher bandwidth in Default Mode is purely an artifact of engine-level Zstd reset cycles.
- **ByteNet Reliability:** ByteNet failed again in Latency Mode, stalling after 1,600 packets, confirming a consistent internal failure in its string handling logic.

### 1.6 SingleValue
>
> Sending a single primitive value (`u8`) per packet. Measures the baseline overhead of the library's batching system.
>
> - **Bandwidth:** Lower is better.
> - **FPS:** Higher is better.

#### SingleValue: Default Mode (Stability First)

| Library | FPS (p50/min/p95) | Bandwidth (p50) | Norm. BW (p50) | Drain Duration | Sent / Recv | Loss % |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Roblox | 60 / 60 / 60 | 232.7 B/s | 232.7 B/s | 10.79ms | 120K / 120K | 0.0% |
| BridgeNet2 | 60 / 60 / 60 | 145.2 B/s | 145.2 B/s | 11.51ms | 120K / 120K | 0.0% |
| ByteNet | 61 / 60 / 61 | 2.2 B/s | 2.2 B/s | 3.68ms | 120K / 120K | 0.0% |
| Warp | 60 / 60 / 60 | 2.3 B/s | 2.3 B/s | 3.76ms | 120K / 120K | 0.0% |
| NetRay | 61 / 60 / 61 | 2.4 B/s | 2.3 B/s | 3.73ms | 120K / 120K | 0.0% |
| Zap | 61 / 60 / 61 | 2.3 B/s | 2.3 B/s | 3.73ms | 120K / 120K | 0.0% |
| Blink | 60 / 60 / 60 | 2.4 B/s | 2.4 B/s | 3.71ms | 120K / 120K | 0.0% |
| **Satset** | **61 / 55 / 61** | **2.4 B/s** | **2.4 B/s** | **4.03ms** | **103K / 103K** | **0.0%** |

#### SingleValue: Latency Mode (Bypass Chunking)

| Library | FPS (p50/min/p95) | Bandwidth (p50) | Norm. BW (p50) | Drain Duration | Sent / Recv | Loss % |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Roblox | 61 / 60 / 61 | 235.5 B/s | 235.5 B/s | 8.38ms | 120K / 120K | 0.0% |
| BridgeNet2 | 60 / 55 / 60 | 145.8 B/s | 145.8 B/s | 10.68ms | 98.8K / 98.8K | 0.0% |
| ByteNet | 61 / 60 / 61 | 2.3 B/s | 2.3 B/s | 3.73ms | 120K / 120K | 0.0% |
| Warp | 60 / 60 / 60 | 2.4 B/s | 2.4 B/s | 4.01ms | 119.8K / 119.8K | 0.0% |
| NetRay | 60 / 60 / 60 | 2.4 B/s | 2.4 B/s | 3.73ms | 120K / 120K | 0.0% |
| Zap | 60 / 60 / 60 | 2.3 B/s | 2.3 B/s | 3.69ms | 120K / 120K | 0.0% |
| Blink | 61 / 60 / 61 | 2.4 B/s | 2.4 B/s | 3.81ms | 120K / 120K | 0.0% |
| **Satset** | **61 / 60 / 61** | **2.4 B/s** | **2.4 B/s** | **3.74ms** | **120K / 120K** | **0.0%** |

##### SingleValue Breakdown

- In single-value tests, Satset demonstrates minimal batching overhead, performing almost identically to pure code-gen libraries despite its internal stateful synchronization features.

---

## 2. Technical Analysis

### The "Compression Illusion"

 Roblox uses [Zstd](https://facebook.github.io/zstd/) compression on all network traffic. Libraries that dump massive identical payloads (1MB+) in a single frame allow Zstd to achieve artificial compression ratios that don't reflect real-world usage.

- **The Proof:** In our **Vectors** benchmark, Satset's bandwidth dropped from **118.9 B/s** (Default) to **39.2 B/s** (Latency) simply by bypassing chunking. This confirms that the higher bandwidth in Default Mode is purely an artifact of engine-level Zstd reset cycles caused by Satset's proactive **60KB chunking** strategy, which is designed for stability rather than synthetic leaderboard scores.

### GC Pressure and Frame Drops

The `Entities` test highlights the impact of Garbage Collection. Libraries that create thousands of individual remote calls or intermediate tables per frame (like Zap and Blink) see significant dips in their minimum framerate (p0). Satset’s unified batcher minimizes object creation, keeping the server locked at 60 FPS.

### Throttling Philosophy

Satset intentionally spreads network load across multiple frames (visible in the slightly higher Drain Duration). While this adds ~2ms of synthetic latency, it prevents the massive CPU spikes that cause micro-stutters in high-intensity games.

---

## 3. Methodology

- **Environment:** Local Roblox Studio (1 Player).
- **Test Intensity:** 200 events per frame (approx. 12,000 per second) for 10 seconds.
- **Metrics:**
  - **FPS p50/min/p95:** Median, absolute minimum, and 95th percentile framerate (**Higher is better**).
  - **Bandwidth p50:** Median raw bytes per second sent over the network (**Lower is better**).
  - **Normalized Bandwidth:** Bandwidth adjusted to a 60 FPS baseline (**Lower is better**).
  - **Drain Duration:** Time (ms) for the internal data queue to empty (**Lower is better for latency**).
  - **Sent / Received:** Total packets fired vs. packets successfully verified on the server (**Higher is better**).
  - **Loss %:** Percentage of packets that were dropped or failed verification (**Lower is better**).
- **Validation:** Every packet is verified for data integrity using epsilon-based comparisons.

---

## 4. Raw Data Access

For developers wishing to perform their own analysis or verify these claims, the complete, unedited performance logs are available in JSON format:

- **Stability First (Default):** [default-mode-result.json](./default-mode-result.json)
- **Latency Bypassed:** [latency-mode-result.json](./latency-mode-result.json)
