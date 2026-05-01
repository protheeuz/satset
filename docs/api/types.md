# Types API

Standard and optimized types for schemas.

## Primitives

| Type | Description | Size |
| :--- | :--- | :--- |
| `u8` | Unsigned 8-bit integer | 1 byte |
| `u16` | Unsigned 16-bit integer | 2 bytes |
| `u32` | Unsigned 32-bit integer | 4 bytes |
| `i8` | Signed 8-bit integer | 1 byte |
| `i16` | Signed 16-bit integer | 2 bytes |
| `i32` | Signed 32-bit integer | 4 bytes |
| `f32` | 32-bit floating point | 4 bytes |
| `f64` | 64-bit floating point | 8 bytes |
| `bool` | Boolean | 1 byte |
| `u4` | 4-bit unsigned integer (0-15) | 1 byte |

## Strings

- `string8`: Max length 255 chars (1 + N bytes). Consists of a 1-byte `u8` length header followed by N bytes of UTF-8 string data.
- `string16`: Max length 65,535 chars (2 + N bytes). Consists of a 2-byte `u16` length header followed by N bytes of UTF-8 string data.

## Roblox Types

- `Vector3`: Standard [IEEE 754 single-precision floating-point format](https://en.wikipedia.org/wiki/Single-precision_floating-point_format) (12 bytes). It writes three 4-byte `f32` values (X, Y, Z).
- `Vector2`: Standard [IEEE 754 single-precision floating-point format](https://en.wikipedia.org/wiki/Single-precision_floating-point_format) (8 bytes). It writes two 4-byte `f32` values (X, Y).
- `Color3`: Compressed RGB (3 bytes). We extract the R, G, and B color channels and write each as a single 1-byte `u8` integer (0-255).
- `CFrame`: Compressed using **"smallest-three" quaternion compression** (18 bytes). Standard uncompressed [Roblox CFrames](https://create.roblox.com/docs/reference/engine/datatypes/CFrame) contain a Vector3 position and a 9-element rotation matrix. Satset compresses the rotation into a quaternion, omits the largest component, and transmits only the 3 smallest components alongside the position.

## Collections

- `optional(type)`: Nullable type. Adds a **1-byte header** (a `u8` boolean flag) to check for `nil`.
- `array(type)`: Array of a specific type. Includes a **2-byte header** (a `u16` integer) for length (max 65,535 elements) followed by the array elements.
- `map(keyType, valType)`: Dictionary mapping. Includes a **2-byte header** (a `u16` integer) for element count. Keys are sorted alphabetically during serialization to ensure deterministic byte order output.
- `enum(values: {string})`: Efficient mapping. Converts string constants into a **single 1-byte `u8` index** corresponding to its array position.

## Specialized

- `Vector3Quantized(range: number)`: Compressed Vector3 (6 bytes). Maps a stud range (default 1024) into 16-bit signed integers. Provides ~0.03 stud precision while reducing size by 50% compared to standard f32.
- `Vector2Quantized(range: number)`: Compressed Vector2 (4 bytes). Same quantization approach for 2D coordinates.
