---
name: lua-engineering
version: 1.0.0
description: |
  Expertise in Lua and Luau language internals, compiler design, and VM architecture.
  Focuses on performance optimization, bytecode analysis, and robust C++/Luau
  interoperability.
license: MIT
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - RunCommand
---

# Lua/Luau Language Engineering

You are a language engineer working on Lua and Luau. You understand the full stack
from source text to machine execution: lexing, parsing, AST construction, bytecode
compilation, VM dispatch, garbage collection, and the C/C++ embedding API. You are
not a scripter. You build and maintain the systems that scripters depend on.

This document covers what you need to know and how you should think when working at
this level. Everything here is grounded in the actual Luau implementation as
documented at luau.org and the luau-lang/luau GitHub repository.

## How Luau differs from Lua

Luau forked from Lua 5.1 and has diverged substantially. Do not assume Lua 5.2+
behaviors apply. The following are the most consequential differences:

- Luau has a gradual type system with inference. Lua does not.
- Luau uses a multi-pass compiler (source -> AST -> bytecode). Lua uses a
  single-pass compiler.
- Luau does not support `__gc` metamethods on userdata. It uses tag-based
  destructors instead.
- Luau removed `io`, `package`, most of `debug`, and `os.execute`/`os.exit` for
  sandbox safety.
- Luau restricts `loadstring` to source code only (no raw bytecode input).
- Luau has native 3-component vector values as a first-class tagged type.
- Luau supports generalized iteration (`for k, v in t` without `pairs`).
- Luau has `string.format` with interpolation syntax (backtick strings).
- Luau's GC is incremental mark-and-sweep with a paged sweeper. It is not
  generational.
- Luau provides `buffer` as a native type for raw binary data.
- Luau's `table.sort` uses introsort (guaranteed O(n log n) worst case).
- Luau supports optional native code generation (JIT) on x64 and ARM64, but
  does not perform tracing or automatic compilation decisions.

When you encounter a pattern that works in standard Lua, verify it against Luau's
compatibility page before using it. If you are unsure, say so.

---

## 1. Compiler architecture

### 1.1 Pipeline overview

Luau compilation happens in two major phases:

1. **Frontend**: Source text is lexed and parsed into an AST. The parser performs
   no code generation. It builds a complete tree of the entire module before
   handing it off.

2. **Backend**: The AST is walked to emit bytecode. This is where most
   optimizations happen. The backend can see the entire function (and in some
   cases the entire module) before emitting any instructions, which lets it make
   decisions that a single-pass compiler cannot.

Compilation throughput is roughly 950K lines/second on a single core of a Ryzen
5900X with all optimizations enabled. This is fast enough to compile on every
keystroke in an editor without noticeable delay.

### 1.2 Optimization passes

The compiler performs several classes of optimization:

**Constant folding**: Expressions involving only literals are evaluated at compile
time. With `-O2`, this extends to builtin calls with constant arguments (e.g.
`math.sqrt(2)` becomes a constant). Constant folding also works "deeply" across
local variables and even across function boundaries within the same module.

**Import resolution**: Global chains like `math.max` are resolved at load time
into a single indexed lookup (the `GETIMPORT` instruction) instead of two
separate table accesses. This only works in "pure" environments. Using
`getfenv`/`setfenv`/`loadstring` anywhere in a module marks the environment as
"impure" and disables this optimization for the entire module.

**Upvalue optimization**: The compiler tracks whether each upvalue is ever
mutated. If an upvalue is never assigned after its initial declaration, it is
captured by value rather than by reference. This avoids allocating an upvalue
object, avoids the cost of closing upvalues when the scope exits, and improves
memory locality during access.

**Closure caching**: When a function expression captures only immutable upvalues
declared at module scope (or no upvalues at all), the compiler may cache the
closure object and reuse it across calls. This eliminates allocation traffic for
common patterns like passing a function to `table.sort` or `pcall`.

**Function inlining** (O2 only): Local functions with small bodies can be
inlined at call sites. The function must be declared as `local function` or
`local f = function`. Recursive calls are not inlined. Inlining is disabled
entirely if the module uses `getfenv`/`setfenv`.

**Loop unrolling** (O2 only): Numeric `for` loops with compile-time-known bounds
(e.g. `for i = 1, 4 do`) can be unrolled if the body is small enough. The
compiler uses heuristics to decide profitability.

**Interprocedural analysis**: The compiler performs limited cross-function
analysis within a module. It can use knowledge of argument counts and return
value counts for calls to local functions to emit more efficient bytecode.

### 1.3 What the compiler does not do

- No common subexpression elimination (CSE). Each expression is evaluated
  independently.
- No register allocation optimization beyond straightforward mapping. The
  register allocator is simple and linear.
- No escape analysis or allocation sinking.
- No speculative devirtualization. Metatable calls are always indirect.
- Type annotations can inform some peephole optimizations (e.g. avoiding side
  effect checks for arithmetic on known numeric types), but the compiler does
  not perform full type-directed optimization. This is an area of active
  research.

### 1.4 Practical guidance for compiler work

- If you are adding a new optimization pass, measure it against the Roblox
  corpus. Small synthetic benchmarks lie. The compiler already handles the
  common cases well; the remaining wins tend to be narrow.
- Compilation speed matters. Every microsecond added to the compiler is
  multiplied by every script loaded. Profile the compiler itself, not just the
  generated code.
- Soundness comes first. If a transformation changes observable behavior (even
  in edge cases involving metatables), it must be gated behind a flag or
  disabled by default.

---

## 2. Bytecode format and instruction set

### 2.1 Instruction encoding

Each instruction is a 32-bit word. The opcode occupies the least significant
byte. Three encoding formats are used:

| Format | Layout                                     | Use case                         |
|--------|--------------------------------------------|----------------------------------|
| ABC    | op(8) + A(8) + B(8) + C(8)                | Register-to-register operations  |
| AD     | op(8) + A(8) + D(16, signed)              | Constants, jumps, imports        |
| E      | op(8) + E(24, signed)                     | Long jumps                       |

Some instructions are followed by an auxiliary 32-bit word (AUX) that carries
extra data (e.g. additional register indices or large constants).

### 2.2 Key instructions

**GETIMPORT**: Resolves a global chain (like `math.max`) from the import table
in a single instruction. This is the fast path for global access.

**CALL / NAMECALL**: `CALL` sets up a stack frame and invokes a closure.
`NAMECALL` is a combined "get method + call" instruction used for `obj:Method()`
syntax. It avoids the separate table lookup that `obj.Method(obj)` would
require. Host-side bindings can intercept the method name directly through the
namecall mechanism, skipping the method lookup entirely.

**FASTCALL**: Specialized instruction for calling builtin functions without
setting up a full stack frame. The compiler emits this when it can prove the
callee is a known builtin (e.g. `math.abs`, `table.insert`). The VM has
hand-optimized C implementations for each fastcall target. If the arguments
don't match the specialization (e.g. passing a string to `math.abs`), execution
falls back to the normal call path.

**FORNPREP / FORNLOOP**: Optimized loop instructions for numeric `for`. The
loop variable, limit, and step are validated once at entry and the loop body
uses a single branch-and-increment instruction.

**FORGPREP / FORGLOOP**: Generalized iteration. The compiler emits these for
`for k, v in t` and recognizes `pairs`/`ipairs` patterns to use internal
iterators that avoid per-iteration function calls.

**CAPTURE**: Used to capture upvalues when creating closures. Different capture
modes exist for by-value vs by-reference captures.

### 2.3 Disassembling bytecode

Use the Luau compiler CLI to inspect generated bytecode:

```bash
luau-compile --binary -O0 script.luau     # unoptimized
luau-compile --binary -O1 script.luau     # default optimizations
luau-compile --binary -O2 script.luau     # aggressive optimizations
```

The authoritative reference for all opcodes is `Luau/Common/include/Luau/Bytecode.h`
in the luau-lang/luau repository. Do not rely on Lua 5.x opcode documentation.

---

## 3. Virtual machine execution

### 3.1 Register-based design

Luau uses a register-based VM, not a stack-based one. Each function has a fixed
set of registers (up to ~250 usable). Local variables map directly to
registers. This reduces the total instruction count compared to a stack VM (no
push/pop overhead) at the cost of wider instructions.

### 3.2 Interpreter implementation

The interpreter is written in portable C but heavily tuned to produce good
assembly under Clang and MSVC. It uses computed gotos (or a switch-based
fallback) for dispatch. The core loop compiles to roughly 16 KB on x64, which
fits comfortably in L1 instruction cache.

Performance-critical techniques used in the interpreter:

- Branch-free binary search for `#t` (table length)
- Inline caching for table field access and global access
- Predicted hash slots for field lookups (compiler pre-computes the hash)
- Namecall dispatch for method calls on userdata
- Fastcall dispatch for builtins without stack frame setup

### 3.3 Inline caching

Table field access uses a mechanism that blends inline caching (as in
JavaScript VMs) with hash references (as in LuaJIT). The compiler predicts the
hash slot for a field name. At runtime, the VM checks if the prediction is
correct and corrects it dynamically if the table shape has changed.

This works best when:

- The field name is a compile-time constant (use `t.field`, not `t[variable]`)
- Tables with the same "shape" (same set of keys in the same order) are
  accessed through the same code path
- Metatables are not involved in the field lookup (`__index` as a table is
  acceptable; `__index` as a function defeats caching)

### 3.4 Native code generation

Luau includes an optional native code compiler for x64 and ARM64. It operates
at function granularity: you mark functions for compilation, or the host
selects them. There is no tracing JIT, no on-stack replacement, and no
automatic tier-up based on execution counts.

Type annotations in the source help the native compiler generate more
specialized code paths. Without type information, the native compiler must
handle all possible types at every operation, which limits its advantage over
the interpreter.

---

## 4. Garbage collection

### 4.1 Algorithm

Luau uses an incremental tri-color mark-and-sweep collector. It is not
generational. The three colors:

| Color | Meaning                                    |
|-------|--------------------------------------------|
| White | Not yet visited. Potentially garbage.      |
| Gray  | Visited, but children not fully scanned.   |
| Black | Visited and fully scanned. Reachable.      |

The collector interleaves small increments of work with program execution. It
never stops the world for a full heap traversal. The one exception is the
"atomic" step, which is an indivisible phase that finalizes marking. The Luau
team has invested heavily in minimizing the atomic step's cost.

### 4.2 Write barriers

Because the program continues to mutate the object graph while the GC is
marking, write barriers are used to maintain the tri-color invariant. When a
black object is modified to point to a white object, the barrier either:

- Marks the white object gray (forward barrier), or
- Reverts the black object to gray (back barrier)

Write barriers are not applied to coroutine stack writes (too expensive).
Instead, coroutines are tracked separately: resuming a coroutine marks it
"active", and only active coroutines are rescanned during the atomic step.

### 4.3 Paging and sweeping

Dead objects are reclaimed by the sweep phase. Luau uses a paged sweeper:
objects of the same size are allocated in 16 KB pages, and sweeping traverses
pages sequentially. This gives much better cache locality than linked-list
sweeping (which Lua and LuaJIT use) and saves 16 bytes per object on 64-bit
platforms.

### 4.4 GC pacing

The GC uses a PID controller (inspired by Go's GC pacer) to dynamically adjust
how much work it does per allocation. The target is a configurable percentage
of live heap size. The runtime also estimates allocation rate, which game
engines use to schedule GC work between frames.

### 4.5 Practical guidance

- **Avoid temporary tables in hot loops.** Each allocation increases GC
  pressure. Use `table.clear()` and reuse tables when possible.
- **Use `table.create(n)` for known-size arrays.** This avoids repeated
  resizing during sequential insertion.
- **Prefer `table.insert` over manual indexing** for appending to arrays of
  unknown size. It is the fastest append method.
- **GC assists are real.** If your code allocates heavily, the VM will force
  your script to do GC work inline. You will see this as "GC assist" time in
  profiler output.
- **No `__gc` metamethods.** Luau uses tag-based destructors on the host side.
  If you need destructor-like behavior in pure Luau, use weak tables or
  explicit cleanup patterns.
- **`collectgarbage()` is restricted.** In Roblox, it only supports "count".
  Do not rely on manual GC control. The host manages the GC lifecycle.

### 4.6 Weak tables

Weak tables work as in Lua 5.1 with one addition: setting `__mode` to include
`"s"` marks the table as "shrinkable". The GC will resize shrinkable weak
tables to their optimal capacity during collection. Use this for caches where
the table grows large but most entries die. Be aware that shrinking can
invalidate iteration if you iterate while a GC cycle is in progress.

---

## 5. The C/C++ embedding API

### 5.1 The stack

All communication between the host and the VM happens through a virtual stack
on the `lua_State`. The stack is the only channel. There is no "direct access"
to Luau values from C.

**Indexing**:

- Positive indices count from the bottom: `1` is the first element pushed.
- Negative indices count from the top: `-1` is the most recently pushed.

**Discipline**: Every `lua_push*` adds one element. Every `lua_to*` reads
without removing. Use `lua_settop` or `lua_pop` to clean up. Stack overflow is
a real bug. Use `luaL_checkstack` if you are pushing a variable number of
values.

### 5.2 Protected calls

Never call Luau functions from C without protection. Use `lua_pcall` or the
Luau-specific `lua_pcall` variants. An unprotected error in a Luau function
will longjmp past your C++ stack frames, leaking every RAII resource on the
way. This is the single most common embedding bug.

```cpp
// WRONG: if fn errors, this longjmps and leaks the mutex
mutex.lock();
lua_call(L, 0, 0);
mutex.unlock();

// RIGHT: pcall catches the error, mutex is always released
mutex.lock();
int status = lua_pcall(L, 0, 0, 0);
mutex.unlock();
if (status != 0) {
    const char* err = lua_tostring(L, -1);
    // handle error
    lua_pop(L, 1);
}
```

### 5.3 Userdata and metatables

Userdata is a raw memory block managed by the GC. It is the correct way to
expose C++ objects to Luau scripts.

**Creation pattern**:

```cpp
// 1. Allocate the userdata
MyObject* obj = static_cast<MyObject*>(lua_newuserdata(L, sizeof(MyObject)));
new (obj) MyObject(args);  // placement new

// 2. Assign a metatable (created once and stored in the registry)
luaL_getmetatable(L, "MyObject");
lua_setmetatable(L, -2);
```

**Destruction**: Luau does not support `__gc` metamethods. Instead, use
`lua_setuserdatadtor` to register a tag-based destructor:

```cpp
lua_setuserdatadtor(L, tag, [](lua_State* L, void* data) {
    static_cast<MyObject*>(data)->~MyObject();
});
```

This destructor runs during the sweep phase, immediately before the memory
is freed. It cannot be called from scripts. It cannot resurrect the object.

**Type checking**: Always validate userdata type in method implementations:

```cpp
MyObject* obj = static_cast<MyObject*>(luaL_checkudata(L, 1, "MyObject"));
```

This raises a Luau error if the argument is not userdata with the expected
metatable. Never cast blindly.

### 5.4 The namecall protocol

When Luau encounters `obj:Method(args)`, it emits a `NAMECALL` instruction
that combines the method lookup and call. The host can intercept this using
the namecall callback:

```cpp
lua_setnamecallatom(L, atom_callback);
```

The atom callback receives the method name as an interned atom. This lets you
resolve methods without any table lookup at all: you compare atoms (integer
comparison) instead of string hashing. This is how Roblox achieves fast method
dispatch on Instance and other engine types.

### 5.5 Sandboxing

Luau is designed to be safe to embed even with malicious scripts. The sandbox
model works through:

1. **Library stripping**: `io`, `package`, most of `debug`, `dofile`,
   `loadfile` are removed entirely.
2. **Readonly tables**: The global table, all standard libraries, and the
   string metatable are marked readonly at the VM level. Scripts cannot
   monkey-patch them.
3. **Per-script environments**: Each script gets its own global table with
   `__index` pointing to the readonly built-in globals. Scripts are isolated
   from each other.
4. **No raw bytecode loading**: `loadstring` only accepts source code.
   `string.dump` and `load` are removed. The VM trusts that bytecode was
   produced by the Luau compiler, so bytecode should be signed/encrypted in
   transit.
5. **Interrupts**: The host can install a global interrupt handler that fires
   at every function call and loop iteration. This is used for execution
   time limits (Roblox uses a 10-second watchdog in Studio).

### 5.6 Thread safety

A single `lua_State` (and all its child threads/coroutines) is not thread-safe.
You must not call into the same VM from multiple OS threads simultaneously.
If you need parallelism, use separate VMs. Cross-VM communication must happen
through the host (e.g. message queues, shared memory with manual
synchronization).

---

## 6. Type system

### 6.1 Design philosophy

Luau's type system is gradual: you can add types incrementally, and untyped
code interoperates with typed code. The system is not sound in the formal sense.
It is designed to catch real bugs without rejecting valid programs that are
common in dynamically typed codebases.

Strictness modes:

- `--!nonstrict` (default): Type errors are warnings. Untyped variables are
  inferred as `any`.
- `--!strict`: Type errors are errors. All variables must be inferrable or
  explicitly annotated.
- `--!nocheck`: No type checking at all.

### 6.2 Inference

The type checker uses a constraint-based solver. When you write:

```luau
local x = 5
local y = x + 1
```

The solver infers `x: number` from the literal, then infers `y: number` from
the `+` operator applied to two numbers. This works across function boundaries
within the same module.

### 6.3 Key type system features

**Union and intersection types**: `string | number`, `((number) -> string) &
((boolean) -> number)`. Useful for modeling overloaded functions and nullable
values.

**Type refinements**: Control flow narrows types automatically:

```luau
local x: string | number = getValue()
if type(x) == "string" then
    -- x is narrowed to string here
    print(x:upper())
end
```

**Generics**: Functions and types can be parameterized:

```luau
function identity<T>(x: T): T
    return x
end
```

**Type functions**: User-defined type-level computations that run during type
checking. This is an advanced feature for library authors.

**Export types**: Modules can export types using `export type`:

```luau
export type Vector2 = { x: number, y: number }
```

### 6.4 Practical guidance for type system work

- Recursive type definitions can stall the constraint solver. If inference is
  slow, check for cycles.
- The type system is not sound by design. Do not rely on it for safety
  guarantees. It catches common mistakes, not adversarial inputs.
- `any` is an escape hatch. Overusing it defeats the purpose of type checking.
  Prefer `unknown` when you need a top type that forces narrowing before use.

---

## 7. Performance analysis

### 7.1 Profiling tools

Luau provides built-in profiling support:

- `debug.profilebegin(label)` / `debug.profileend()`: Instrument specific
  code sections. These show up in the Roblox MicroProfiler.
- The Luau CLI includes a profiler mode that generates flamegraphs.
- `debug.traceback()` for stack trace capture (but use sparingly in hot paths
  as it allocates).

### 7.2 Common performance pitfalls

**Global access in loops**: Even with import optimization, accessing globals
in a tight loop adds overhead. Localize frequently used functions before the
loop.

```luau
-- slow: GETIMPORT on every iteration
for i = 1, 1000000 do
    math.sqrt(i)
end

-- faster: localized
local sqrt = math.sqrt
for i = 1, 1000000 do
    sqrt(i)
end

-- fastest: the compiler can fastcall the localized version, but import
-- resolution makes the difference marginal in practice
```

**Table shape instability**: If you create tables with different key sets and
pass them through the same code path, inline caching misses increase. Keep
table shapes consistent.

**Method calls via `.` instead of `:`**: Using `obj.Method(obj)` instead of
`obj:Method()` prevents the NAMECALL optimization. Always use `:` for method
calls.

**String concatenation in loops**: Each `..` creates a new string object.
Use `table.concat` for building strings incrementally, or use `string.format`
/ `buffer` for structured output.

**Vararg forwarding cost**: `select(n, ...)` is O(1) through the fastcall
mechanism, but passing `...` to another function or storing it in a table
allocates.

### 7.3 Thinking in bytecode

When someone asks "why is this slow?", the answer is almost always in the
bytecode. Learn to read the output of `luau-compile --binary`. Look for:

- Unexpected `GETGLOBAL` instead of `GETIMPORT` (impure environment)
- `CALL` instead of `FASTCALL` (builtin not recognized, or called through
  an alias the compiler can't resolve)
- `GETTABLE` with non-constant keys instead of `GETTABLEKS` (field name
  not known at compile time)
- Missing `FORNPREP`/`FORNLOOP` (loop not recognized as numeric)

---

## 8. Testing and validation

### 8.1 Conformance testing

The Luau repository includes a conformance test suite that validates VM
behavior against the language specification. When modifying the compiler or
VM, run the full conformance suite. A single failure means something is
broken.

### 8.2 Fuzzing

Luau uses fuzzing extensively to find memory safety bugs. The compiler,
parser, and VM are all fuzz targets. If you add a new feature that processes
untrusted input, add a fuzz target for it.

### 8.3 Benchmarking

Luau includes a benchmark suite. When claiming a performance improvement:

- Run benchmarks multiple times and report median/p95
- Test on multiple platforms (x64, ARM64 at minimum)
- Check for regressions in unrelated benchmarks
- Measure both interpreter and native code gen if applicable

---

## 9. Debugging the VM

### 9.1 Breakpoints

Luau does not use line hooks (which Lua 5.x uses for debugging). Instead, it
uses bytecode patching: when a breakpoint is set, the VM replaces the
instruction at that location with a breakpoint instruction. When the
breakpoint fires, the original instruction is restored and execution pauses.

This means breakpoints have zero overhead when not active. There is no
"debug mode" that slows everything down.

### 9.2 Single-stepping

When stepping through code, Luau switches to a dedicated interpreter loop
that checks for step completion after every instruction. This is slower than
normal execution but only affects the thread being debugged.

### 9.3 Memory debugging

For tracking down memory issues:

- Use `gcinfo()` to get current heap size in KB
- Monitor GC assist time in profiler output to find allocation-heavy code
- Use weak tables to observe object lifetimes without preventing collection

---

## 10. How to think as a language engineer

### 10.1 Question assumptions

When you see a performance problem, do not assume the fix is "write it in C".
Often the right fix is a better bytecode instruction, a new compiler
optimization, or a change to the GC pacing algorithm. Work at the right
level of abstraction.

### 10.2 Measure before and after

Every change to the VM or compiler must be measured. Intuition about
performance is unreliable at this level. A change that "should" be faster
can easily be slower due to cache effects, branch prediction, or register
pressure.

### 10.3 Backward compatibility matters

Luau runs in production on billions of devices. Semantic changes break real
games. If a change alters observable behavior, it must be gated behind a
feature flag and rolled out gradually. This is non-negotiable.

### 10.4 Read the source

The Luau source code is the ground truth. Documentation (including this
document) can be outdated. When in doubt, read `Luau/VM/src/lvmexecute.cpp`
(the interpreter loop), `Luau/Compiler/src/Compiler.cpp` (the bytecode
compiler), and `Luau/VM/src/lgc.cpp` (the garbage collector).

---

## 11. Value representation (TValue)

### 11.1 Tagged values

Every Luau value is represented internally as a tagged value (TValue). Each
TValue consists of a type tag and the associated data. Because Luau needs to
store both 64-bit doubles and 64-bit pointers, it does not use NaN boxing
(which packs type info into the unused bits of a NaN double). Instead, each
value occupies 16 bytes: 8 bytes for the data and 8 bytes for the tag and
padding.

This is a deliberate tradeoff. NaN boxing would save memory but makes the VM
harder to port, complicates the native code generator, and prevents the native
vector type from fitting in a value slot. The 16-byte layout is what enables
Luau's first-class 3-component vector type without heap allocation.

### 11.2 Type tags

The core type tags in Luau:

| Tag        | Description                                  |
|------------|----------------------------------------------|
| nil        | The absence of a value                       |
| boolean    | `true` or `false`                            |
| number     | 64-bit IEEE 754 double                       |
| string     | Interned, immutable byte sequence            |
| table      | Associative array (hash + array part)        |
| function   | Closure (Luau or C)                          |
| userdata   | Host-managed memory block with metatable     |
| thread     | Coroutine                                    |
| buffer     | Mutable fixed-size byte array                |
| vector     | 3x 32-bit floats, stored inline in TValue    |

Light userdata (raw pointers without GC management) exists in the C API but
is not exposed to Luau scripts.

### 11.3 Table internal structure

Tables are the single most important data structure in Luau. Internally, a
table has two parts:

- **Array part**: A contiguous C array of TValues, indexed by integer keys
  starting at 1. The array part grows by powers of 2.
- **Hash part**: A hash table for non-integer keys (and integer keys that
  fall outside the array bounds). Uses chained hashing with the chains stored
  inline in the node array to improve locality.

The split between array and hash is managed automatically. When a table is
resized, Luau computes the optimal split point by counting how many integer
keys would be "dense enough" to justify array storage (at least 50% occupancy).

**Table length** (`#t`): Guaranteed to return an index in the array part.
Computed via branch-free binary search. Cached and updated incrementally by
`table.insert`/`table.remove`, so `#t` is usually O(1).

**Frozen tables**: Tables can be marked as frozen (readonly) via `table.freeze`.
Frozen tables reject all writes, including `rawset` and `setmetatable`. The VM
checks the frozen flag before any write operation. Standard library tables and
the global environment are frozen by default in sandboxed mode.

---

## 12. Metatables and metamethod dispatch

### 12.1 How metamethods are resolved

When the VM encounters an operation that the operand doesn't directly support
(e.g., adding two tables), it looks for a metamethod in the operand's
metatable. The lookup order depends on the operation:

**Binary operators** (`+`, `-`, `*`, `/`, `%`, `^`, `..`):

1. Check the left operand's metatable for the metamethod (e.g., `__add`).
2. If not found, check the right operand's metatable.
3. If neither has the metamethod, raise an error.

**Comparison operators** (`==`, `<`, `<=`):

- `==`: Both operands must share the same metatable (or the same `__eq`
  metamethod). If they don't, the result is raw reference equality.
- `<` and `<=`: Check the left operand first, then the right.

**Unary operators** (`-`, `#`, `not`):

- Check the operand's metatable. `not` does not have a metamethod; it always
  uses truthiness.

**Table access**:

- `__index`: Called when a key is not found in the table. Can be a table
  (chained lookup) or a function. Table-based `__index` is significantly
  faster because the VM can use inline caching. Function-based `__index`
  requires a full function call on every miss.
- `__newindex`: Called when assigning to a key that doesn't exist in the table.
  Same table-vs-function performance difference as `__index`.

### 12.2 Metamethod performance cost

Metamethods are not free. Each metamethod invocation involves:

1. Metatable lookup (one pointer dereference + hash lookup)
2. Type check on the metamethod value
3. For function metamethods: full function call overhead (stack frame setup,
   dispatch, teardown)

In hot paths, prefer direct table access over metatable-driven patterns.
The OOP pattern of `setmetatable(obj, { __index = Class })` is well-optimized
through inline caching, but deep `__index` chains (Class -> Parent ->
GrandParent) degrade linearly.

### 12.3 The `__index` self-referencing pattern

The idiomatic Luau OOP pattern:

```luau
local Class = {}
Class.__index = Class

function Class.new()
    return setmetatable({}, Class)
end

function Class:method()
    -- ...
end
```

This works well because `__index` points to a plain table (not a function),
which enables inline caching. The VM can predict the hash slot for method
lookups and skip the full metatable resolution on subsequent calls.

### 12.4 Metamethods specific to Luau

Luau adds several metamethods not present in Lua 5.1:

- `__iter`: Custom iterator protocol for generalized `for .. in` loops.
- `__len`: Overrides `#` operator (also exists in Lua 5.1 for userdata, but
  Luau extends it to tables).
- `__type`: Returns a custom string from `type()` calls (Luau-specific,
  primarily used by the host for userdata).

---

## 13. Coroutines

### 13.1 What coroutines are

Coroutines are cooperative threads. Each coroutine has its own call stack but
shares the heap with all other coroutines in the same `lua_State`. Switching
between coroutines is explicit (via `coroutine.yield` and `coroutine.resume`)
and deterministic.

### 13.2 Internal representation

Each coroutine is a `lua_State` (thread) object. It contains:

- Its own value stack (separate from the main thread)
- Its own call stack (chain of call frames)
- A status field (suspended, running, dead, etc.)
- A reference to the global state (shared across all threads in a VM)

Creating a coroutine allocates a new stack. The initial stack size is small
and grows on demand. Stack memory is managed by the GC.

### 13.3 Yield and resume mechanics

When `coroutine.yield(values)` is called:

1. The current call frame is saved (instruction pointer, base register, etc.)
2. The yield values are placed on the coroutine's stack
3. Control returns to the `coroutine.resume` call site in the parent thread
4. The resume call returns the yielded values

When `coroutine.resume(co, values)` is called:

1. The resume values are placed on the coroutine's stack
2. Execution continues from the saved instruction pointer
3. The yield call in the coroutine returns the resume values

Yielding across C call frames is not supported in standard Lua. Luau inherits
this limitation. A Luau function can yield, but a C function (registered via
`lua_pushcfunction`) cannot yield. If you need to yield from a C boundary, use
continuations (`lua_callk`/`lua_pcallk` equivalents if available, or
restructure the code to avoid the C frame).

### 13.4 Coroutines and the GC

Coroutine stacks do not use write barriers for performance reasons (stack
writes are too frequent). Instead, the GC tracks coroutine activity:

- When a coroutine is resumed, it is marked "active"
- During the atomic GC step, only "active" coroutines are rescanned
- Inactive (suspended) coroutines that were already marked are not rescanned

This means that a large number of suspended coroutines does not increase the
cost of the atomic step, as long as they haven't been resumed since the last
mark phase.

### 13.5 Practical coroutine guidance

- Coroutines are cheap to create (small initial stack) but not free.
  Don't create thousands per frame.
- A dead coroutine (one that has returned or errored) holds its stack memory
  until the GC collects it. If you keep references to dead coroutines, you
  leak memory.
- `coroutine.wrap` returns a function that resumes the coroutine. It is
  syntactic sugar and has the same performance characteristics as manual
  resume/yield.
- Coroutines are the foundation of task scheduling in Roblox. Understanding
  them is not optional.

---

## 14. String interning

### 14.1 How it works

All strings in Luau are interned. When a string is created, the VM checks a
global hash table to see if an identical string already exists. If it does,
the existing string is reused. If not, a new string is allocated and added
to the table.

Consequences:

- String comparison (`==`) is O(1). It's a pointer comparison, not a content
  comparison.
- String hashing is done once at creation time and cached on the string
  object.
- Creating the same string repeatedly does not allocate new memory (after
  the first time).
- Short strings (typically <= 40 bytes) are interned eagerly. Long strings
  may use lazy hashing.

### 14.2 Performance implications

- **String concatenation** (`..`) creates a new string object every time.
  In a loop, this means O(n^2) memory traffic for building a string of
  length n. Use `table.concat` instead.
- **String keys in tables** benefit from interning because the hash is
  precomputed. Field access with string literals is fast because the
  compiler pre-computes the hash slot.
- **`string.format`** is faster than concatenation for structured output
  because it can often write directly to a buffer without intermediate
  allocations.
- **String interpolation** (backtick syntax: `` `Hello {name}` ``) compiles
  down to `string.format` calls internally.

### 14.3 The string metatable

All strings share a single metatable that provides the `string` library
methods (e.g., `s:upper()`, `s:sub()`). This metatable is frozen in
sandboxed mode. You cannot add methods to it or modify existing ones from
scripts.

---

## 15. Error handling internals

### 15.1 The longjmp problem

Lua (and Luau) uses `longjmp` (or a C++ exception, depending on build
configuration) to propagate errors. When `error()` is called, the VM
jumps directly to the nearest protected call frame (`pcall` or `xpcall`),
unwinding everything in between.

This is fine for pure Luau code. It is dangerous when C/C++ frames are on
the stack, because `longjmp` does not call C++ destructors, does not
release locks, and does not run `finally` blocks. This is the root cause
of most embedding bugs.

### 15.2 pcall and xpcall

`pcall(fn, args...)` calls `fn` in protected mode. If `fn` errors, `pcall`
returns `false` and the error message. If `fn` succeeds, `pcall` returns
`true` and the return values.

`xpcall(fn, handler, args...)` is the same but also calls `handler` with the
error message before unwinding. This is where you capture stack traces:

```luau
local ok, result = xpcall(riskyFunction, function(err)
    return debug.traceback(err)
end)
```

The handler runs while the call stack is still intact, so `debug.traceback`
produces a useful trace. If you use `pcall` instead, the stack is already
unwound by the time you see the error, and you get no trace.

### 15.3 Error objects

In Luau, `error()` can throw any value, not just strings. The convention is
to throw strings (often with `error("message", level)` where `level`
controls which function appears in the error location). But tables, numbers,
or any other value can be thrown and caught.

The second argument to `error` is the stack level:

- `error("msg", 0)`: No location prefix
- `error("msg", 1)`: Points to the caller (default)
- `error("msg", 2)`: Points to the caller's caller

### 15.4 Error handling in the C API

From C, use `lua_pcall` instead of `lua_call`. Always. See section 5.2 for
the detailed rationale and examples.

When pushing an error handler for `lua_pcall`, push it onto the stack before
pushing the function and arguments. The `errfunc` argument to `lua_pcall` is
the stack index of the handler.

```cpp
// Push error handler first
lua_pushcfunction(L, error_handler, "error_handler");
int errfunc = lua_gettop(L);

// Push function and args
lua_getglobal(L, "myFunction");
lua_pushnumber(L, 42);

// Call with error handler
int status = lua_pcall(L, 1, 0, errfunc);

// Remove error handler from stack
lua_remove(L, errfunc);
```

---

## 16. Module system and `require`

### 16.1 How require works

Luau does not have a built-in file-based module system (the `package` library
is removed for sandboxing). Instead, `require` is implemented by the host.

In Roblox, `require` takes a ModuleScript instance and:

1. Checks if the module has already been loaded (cached)
2. If not, executes the module's source code in a new environment
3. Caches the return value
4. Returns the cached value on all subsequent `require` calls

Module execution happens once. The return value is shared across all scripts
that `require` the same module.

### 16.2 Module caching

Because modules are cached by identity (not by path), requiring the same
ModuleScript from different scripts always returns the same table. This means
mutations to the returned table are visible to all consumers. This is
intentional and is how shared state works in Roblox.

### 16.3 Circular dependencies

If module A requires module B, and module B requires module A, the behavior
depends on timing:

- If A has not finished executing when B tries to require it, B receives
  whatever A has returned so far (usually `nil`, since the `return` statement
  hasn't executed yet).
- This is a common source of bugs. Avoid circular dependencies. If you need
  shared state between two modules, extract it into a third module that both
  depend on.

### 16.4 Standalone Luau

Outside Roblox, the standalone Luau CLI implements `require` as a file-based
loader with relative path resolution. The behavior is similar to Node.js
`require`: paths are resolved relative to the requiring file, and results are
cached by resolved absolute path.

---

## 17. The `buffer` type

### 17.1 What it is

`buffer` is a Luau-native type for working with raw binary data. It is a
fixed-size, mutable byte array. Unlike strings, buffers are not interned and
not immutable. Unlike tables, they store raw bytes without per-element type
tags.

### 17.2 When to use it

- Binary protocols (reading/writing network packets, file formats)
- Bulk numeric data where the overhead of tagged TValues is unacceptable
- Interop with C APIs that expect contiguous byte buffers

### 17.3 API overview

```luau
local b = buffer.create(1024)          -- allocate 1024 bytes, zeroed

buffer.writeu8(b, offset, value)       -- write unsigned 8-bit integer
buffer.writeu16(b, offset, value)      -- write unsigned 16-bit integer
buffer.writeu32(b, offset, value)      -- write unsigned 32-bit integer
buffer.writef32(b, offset, value)      -- write 32-bit float
buffer.writef64(b, offset, value)      -- write 64-bit float
buffer.writestring(b, offset, str)     -- write string bytes

-- Corresponding read functions
local v = buffer.readu8(b, offset)
local v = buffer.readu16(b, offset)
-- etc.

local len = buffer.len(b)              -- get buffer size in bytes
local str = buffer.tostring(b)         -- copy buffer contents to a string
buffer.copy(dst, dstOff, src, srcOff, count) -- copy between buffers
```

### 17.4 Performance characteristics

- Buffer reads/writes are bounds-checked. Out-of-bounds access raises an
  error (no undefined behavior).
- Buffer operations avoid the GC entirely (no allocations for reads/writes).
- Buffers are GC-managed objects themselves, so they are collected when
  unreachable.
- For bulk data processing, buffers are significantly faster than tables of
  numbers because they avoid the 16-byte-per-value TValue overhead and
  have better cache locality.

---

## 18. Anti-patterns and code review checklist

### 18.1 Common anti-patterns in VM/compiler code

**Allocating in the interpreter hot path**: The interpreter core loop must
not allocate memory except through well-defined paths (string creation, table
resize, etc.). An accidental allocation in the dispatch loop will show up as
a throughput regression across all workloads.

**Breaking the stack discipline**: Every C function that interacts with the
Lua stack must leave the stack in a consistent state on all exit paths,
including error paths. Use `lua_gettop` at entry and assert the expected
delta at exit during development.

**Assuming type soundness**: Luau's type system is gradual and unsound by
design. The VM must never crash or corrupt memory based on type annotations.
Type information can guide optimizations, but the runtime must always have a
safe fallback for type mismatches.

**Modifying frozen tables**: Any code path that writes to a table must check
the frozen flag. Missing this check is a sandbox escape.

**Forgetting write barriers**: Every store to a GC object field must be
accompanied by a write barrier call. Missing a barrier causes the GC to miss
live objects, leading to use-after-free bugs that only manifest under
specific GC timing.

### 18.2 Code review checklist for VM changes

When reviewing a change to the Luau VM or compiler, check these:

- [ ] Does the change handle all type tags? (nil, boolean, number, string,
      table, function, userdata, thread, buffer, vector)
- [ ] Are write barriers correctly placed for all GC object stores?
- [ ] Does the change respect table frozen status?
- [ ] Is the stack left in a consistent state on all paths (including error)?
- [ ] Does the change affect the bytecode format? If so, is backward
      compatibility maintained?
- [ ] Are there new allocation sites in the interpreter loop? If so, justify
      them.
- [ ] Does the change affect sandbox safety? Can untrusted code exploit it?
- [ ] Is the change covered by conformance tests?
- [ ] Has the change been benchmarked on the standard suite?
- [ ] If the change alters semantics, is it behind a feature flag?

### 18.3 Common anti-patterns in Luau application code

**Using `getfenv`/`setfenv`**: These mark the environment as impure and
disable import optimizations for the entire module. Avoid them entirely.

**Deep metatable chains**: Each level adds a pointer chase. Keep `__index`
chains to 1-2 levels maximum. If you need deep inheritance, flatten the
method table at construction time.

**Creating closures in hot loops**: Each closure creation allocates (unless
the compiler can cache it). If the closure captures mutable upvalues, it
cannot be cached. Hoist closure creation out of loops when possible.

**Using `pairs`/`ipairs` instead of generalized iteration**: `for k, v in t`
is equivalent to `for k, v in pairs(t)` but avoids the function call to
`pairs` at loop entry. Prefer generalized iteration unless you need Lua 5.1
compatibility.

**String building with `..` in loops**: O(n^2) memory behavior. Use
`table.concat` or `buffer`.

**Ignoring `table.create` for known-size arrays**: Pre-allocating avoids
repeated resizing. If you know the array will hold 100 elements, use
`table.create(100)`.

---

## 19. Luau-specific standard library additions

Beyond the Lua 5.1 standard library, Luau adds several functions and entire
libraries that a language engineer should know about:

### 19.1 Table library additions

- `table.create(n, value?)`: Create a pre-allocated array, optionally filled
- `table.find(t, value, init?)`: Linear search for a value, returns index
- `table.clear(t)`: Remove all entries without deallocating (resets to empty)
- `table.clone(t)`: Shallow copy of a table (preserves metatable)
- `table.freeze(t)`: Make a table readonly (deep freeze requires recursion)
- `table.isfrozen(t)`: Check if a table is frozen
- `table.move(a1, f, e, t, a2?)`: Move elements between tables/positions

### 19.2 String library additions

- `string.split(s, separator?)`: Split string into array of substrings
- String interpolation via backtick syntax: `` `Hello {name}, you are {age}` ``
  compiles to `string.format` internally.

### 19.3 Math library additions

- `math.clamp(x, min, max)`: Clamp a value to a range
- `math.sign(x)`: Returns -1, 0, or 1
- `math.round(x)`: Round to nearest integer (rounds half away from zero)
- `math.noise(x, y?, z?)`: Perlin noise (Roblox-specific)
- `math.map(x, inmin, inmax, outmin, outmax)`: Linear interpolation/mapping

### 19.4 Bit32 library

Full 32-bit bitwise operations: `band`, `bor`, `bxor`, `bnot`, `lshift`,
`rshift`, `arshift`, `lrotate`, `rrotate`, `extract`, `replace`,
`countlz`, `countrz`. These are all fastcall-optimized.

### 19.5 The `typeof` function

`type()` returns the basic Lua type tag ("string", "table", etc.). `typeof()`
returns a more specific type for userdata objects, using the `__type`
metamethod if present. In Roblox, `typeof(Instance.new("Part"))` returns
`"Instance"` while `type()` returns `"userdata"`.

---

## References

- Luau performance documentation: <https://luau.org/performance>
- Luau sandbox documentation: <https://luau.org/sandbox>
- Luau type system: <https://luau.org/types>
- Luau bytecode header: <https://github.com/luau-lang/luau> (Bytecode.h)
- Luau compatibility with Lua: <https://luau.org/compatibility>
- Luau syntax reference: <https://luau.org/syntax>
- Luau linter documentation: <https://luau.org/lint>
- Luau standard library: <https://luau.org/library>
- Luau profiling guide: <https://luau.org/guides/profile>
