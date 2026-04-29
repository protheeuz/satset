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

- `string8`: Max length 255 chars (1 + N bytes).
- `string16`: Max length 65,535 chars (2 + N bytes).

## Roblox Types

- `Vector3`: Standard IEEE 754 f32 (12 bytes).
- `Vector2`: Standard IEEE 754 f32 (8 bytes).
- `Color3`: Compressed RGB (3 bytes, 1 byte per channel).
- `CFrame`: Compressed using **"smallest-three" quaternion compression** (18 bytes). We omit the largest quaternion component and reconstruct it on the receiver, saving over 10 bytes per frame.

## Collections

- `optional(type)`: Nullable type. Adds a **1-byte header** to check for `nil`.
- `array(type)`: Array of a specific type. Includes a **2-byte header** for length (max 65,535 elements).
- `map(keyType, valType)`: Dictionary mapping. Includes a **2-byte header** for element count. Keys are sorted alphabetically during serialization to ensure deterministic output.
- `enum(values: {string})`: Efficient mapping. Converts string constants into a **single u8 index**.

## Specialized

- `Vector3Quantized(range: number)`: Compressed Vector3 (6 bytes). Maps a stud range (default 1024) into 16-bit signed integers. Provides ~0.03 stud precision while reducing size by 50% compared to standard f32.
- `Vector2Quantized(range: number)`: Compressed Vector2 (4 bytes). Same quantization approach for 2D coordinates.
