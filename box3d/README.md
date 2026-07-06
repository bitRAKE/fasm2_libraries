# Box3D bindings for fasm2

fasm2 bindings for the Box3D C interface, for the default library build:
single precision (no `BOX3D_DOUBLE_PRECISION`), Windows x64, MSVC layout.
Distributed separately from Box3D as a self-contained directory:

```
box3d\
  examples\      example programs and shaders
  include\       fasm2 bindings + the Box3D C headers
  shared\        box3d.dll, its import library, and the box3d-Oz.dll drop-in
  static\        static box3d.lib (thin-LTO bitcode; link with lld-link)
  tests\         layout and ABI verification
  LICENSE.box3d  original box3d license, note SPDX headers
  README.md
```

The shipped libraries are clang thin-LTO `-O3` builds for the generic
x86-64 baseline -- measurably faster than an MSVC `/O2` build with
bit-identical simulation results (see the measurements at the end).
`shared\box3d-Oz.dll` is a size-optimized (29% smaller) build of the same
sources: rename it over `box3d.dll` to use it. All flavors produce
identical results, verified by the ABI conformance hash in `tests\`.

## Integration

Add the distribution's `include` directory to the `INCLUDE` environment
variable. That is the only setup: fasm2 resolves `include 'box3d.inc'`
through `INCLUDE`, and the same path serves the MSVC compiler for the C
headers (`#include "box3d/box3d.h"`), which the test suite uses.

Nothing in the sources assumes where the distribution lives; examples,
tests, and your own programs refer to the bindings by name only.

| File | Purpose |
| --- | --- |
| `include\box3d.inc` | Constants, enums, and all public struct layouts (`struct`/`sizeof.`/field offsets). Requires fasm2's `macro/struct.inc` and includes it itself unless another include (like `win64a.inc`) already has. |
| `include\box3d.extrn.inc` | `extrn` declarations for all 578 `B3_API` functions, for `format MS64 COFF` objects linked against `static\box3d.lib` or the `shared\box3d.lib` import library. Only symbols you use are declared. |
| `include\box3d.api.inc` | Import list for `format PE64` executables importing `box3d.dll` directly with `macro/import64.inc` (no linker needed). Only symbols you use are imported. |
| `include\box3d\*.h` | The Box3D C headers, matching the shipped libraries. Used by the verification suite; also lets C and asm share one include path. |

## Using the bindings

COFF object linked by MSVC `link` (works with either library flavor):

```asm
format MS64 COFF
include 'box3d.inc'
include 'box3d.extrn.inc'
...
call    b3CreateWorld
```

```bat
fasm2 program.asm
lld-link program.obj static\box3d.lib libcmt.lib legacy_stdio_definitions.lib
```

The static library contains LLVM bitcode (thin LTO, so cross-module
optimization happens at your application link), which requires `lld-link`
-- a drop-in replacement for `link` that ships with Visual Studio's LLVM
component. The import library `shared\box3d.lib` is ordinary COFF and
works with either linker.

PE64 executable importing `box3d.dll` directly, no linker:

```asm
format PE64 console
include 'macro/import64.inc'
include 'box3d.inc'
...
call    [b3CreateWorld]           ; imported functions are called indirectly

section '.idata' import data readable
library box3d,'box3d.dll'
include 'box3d.api.inc'
```

Run with `box3d.dll` (from `shared\`) next to the executable.

## ABI notes

- The Windows x64 calling convention applies. Structs of 1, 2, 4, or 8
  bytes (`b3WorldId`, `b3BodyId`, `b3ShapeId`, `b3JointId`) pass and return
  by value in a GP register.
- Larger structs (`b3Vec3`, `b3Pos`, `b3Version`, `b3WorldDef`, ...) are
  passed by pointer to a caller-owned copy and *returned through a hidden
  pointer argument in RCX*, shifting the visible parameters right by one.
- `bool` is one byte (and only AL is defined on return); enums are 4 bytes.
- `b3Pos`, `b3WorldTransform`, and `b3WorldCastOutput` are defined as their
  single precision layouts (`b3Vec3`/`b3Transform`/`b3CastOutput`), matching
  the C typedefs when `BOX3D_DOUBLE_PRECISION` is off. A double precision
  library build changes the ABI and is not covered by these bindings.
- `b3InternalAssert` is declared in the headers but only exists in debug
  builds (or with `B3_ENABLE_ASSERT`); release `box3d.dll` does not export it.
- Three struct fields collide with fasm2 directive names and are declared
  with the `label name: type` idiom instead of a data definition:
  `b3CollisionPlane.push`, `b3MeshNode.data`, `b3Mesh.data`. Their offsets
  are unchanged; they are just not initializable in a struct literal.

## Examples

Assemble with `fasm2` (the `include` directory on `INCLUDE`); the GUI
examples run with `box3d.dll` next to the executable.

- `drop_coff.asm` / `drop_pe.asm` -- minimal free-fall programs showing
  the COFF-plus-linker and direct-DLL-import paths.
- `pyramid.asm` -- a pyramid of boxes, one draw call per body with the
  transform passed as uniforms (the simple path). SPACE detonates a
  `b3World_Explode` at the base, R rebuilds, ESC quits.
- `benchmark.asm` -- a multithreaded stress test: 49600 boxes with
  randomized rotations collapse into a pile with sleeping enabled. Box3D
  runs its own internal scheduler; +/- steps the worker count at runtime
  and ]/[ the sub-step count, with live counters in the title bar.
  Rendering is fully instanced through a persistently mapped GL 4.4
  buffer, refreshed from `b3World_GetBodyEvents` with zero per-body API
  calls.
- `dismount.asm` -- artistic stair dismount: a ten-body jointed ragdoll
  is launched down a staircase and judged on style (flips, rolls, twists,
  steps contacted, wall rides, air time), with the scorecard printed to
  the console.

## Verification

`tests\run_tests.cmd` (from a vcvars64 prompt, with fasm2 on `PATH` or
named by `FASM2`, and python available) prefers `lld-link` when present
-- required for the shipped LTO static library -- and runs three layers:

1. **Layout**: `gen_layout.py` parses `box3d.inc` and emits a C program
   that prints one fasmg `assert` per struct, field, and constant using
   the compiler's `sizeof`/`offsetof`; `test_layout.asm` assembles the
   bindings against that output, so any mismatch fails assembly.
2. **ABI conformance**: `api_check.c` and `api_check.asm` drive an
   identical deterministic sequence of ~90 calls covering every distinct
   calling-convention shape in the interface -- hidden-pointer returns
   from 12 to 440 bytes, register struct returns (including the
   float-pair `b3CosSin`), by-reference arguments, XMM and stack floats,
   5..8-argument calls, bool returns in AL, out-pointers, and Box3D
   calling back into the module -- folding every result into `b3Hash`.
   The per-phase hashes must match bit for bit; the asm side reproduces
   130 simulation steps of the C reference exactly.
3. **Examples**: the drop program is linked against the static library
   and the import library and run alongside the direct-import PE. When
   `shared\box3d-Oz.dll` is present, the ABI hash is also checked against
   the size-optimized DLL before the examples run.

One C-side subtlety the harness works around: structs returned by value
carry indeterminate padding bytes (a `{0}` initializer need not zero
padding), so folds cover only padding-free byte ranges. The box hulls are
the exception -- Box3D zeroes their padding explicitly because hull
identity is a content hash.

Re-run the suite whenever the libraries are rebuilt from newer Box3D
sources.

## Ancillary: building the libraries

The shipped libraries were produced from the Box3D sources
(https://github.com/erincatto/box3d) with Visual Studio and CMake:

```bat
rem static library -> build-static\src\Release\box3d.lib
cmake -S . -B build-static -G "Visual Studio 18 2026" -DBOX3D_SAMPLES=OFF -DBOX3D_UNIT_TESTS=OFF -DBUILD_SHARED_LIBS=OFF
cmake --build build-static --config Release --target box3d

rem DLL + import library -> build-shared\bin\Release\box3d.dll, build-shared\src\Release\box3d.lib
cmake -S . -B build-shared -G "Visual Studio 18 2026" -DBOX3D_SAMPLES=OFF -DBOX3D_UNIT_TESTS=OFF -DBUILD_SHARED_LIBS=ON
cmake --build build-shared --config Release --target box3d
```

`package.cmd` (in the binding development tree) collects the bindings,
headers, examples, tests, and built libraries into the distribution
layout above.

### Optimized builds (clang-cl + LTO)

VS ships clang-cl, lld-link, and Ninja, which support thin LTO and the
full range of LLVM optimization levels while staying ABI-compatible with
the MSVC builds (same struct layout, same static CRT). From a vcvars64
prompt, for a distributable generic-ISA `-O3` build:

```bat
cmake -S . -B build-lto-O3-shared -G Ninja ^
  -DCMAKE_C_COMPILER=clang-cl -DCMAKE_CXX_COMPILER=clang-cl -DCMAKE_LINKER=lld-link ^
  -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON ^
  -DBOX3D_SAMPLES=OFF -DBOX3D_UNIT_TESTS=OFF ^
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON ^
  "-DCMAKE_C_FLAGS=/clang:-ffp-contract=off" ^
  "-DCMAKE_CXX_FLAGS=/clang:-ffp-contract=off" ^
  "-DCMAKE_C_FLAGS_RELEASE=/clang:-O3 /DNDEBUG" ^
  "-DCMAKE_CXX_FLAGS_RELEASE=/clang:-O3 /DNDEBUG"
cmake --build build-lto-O3-shared --target box3d
```

Swap `BUILD_SHARED_LIBS=OFF` for the static variant, `-Oz` for a
size-optimized build, and add `/clang:-march=native` to `CMAKE_C_FLAGS`
for a machine-specific build (not distributable).

Measured on the benchmark example scene (49600 boxes, one sample at 1 and
16 workers, same wall-clock methodology):

| build | DLL size | 1 worker | 16 workers |
| --- | --- | --- | --- |
| MSVC `/O2` (stock) | 1064 KB | 734 ms | 61 ms |
| clang LTO `-O3` generic | 1108 KB | 698 ms | 53 ms |
| clang LTO `-Oz` generic | 755 KB | 889 ms | 60 ms |
| clang LTO `-O3` native | 1187 KB | 598 ms | 52 ms |

Observations:

- Generic `-O3` beats MSVC by ~14% multithreaded and even matches the
  `-march=native` build there; the solver is memory-bound at high worker
  counts, so the wider native ISA only pays off single-threaded (-19%).
  `-O3` generic is the best distributable default.
- `-Oz` is 29% smaller than the stock DLL and holds parity with MSVC
  multithreaded, at a ~21% single-thread penalty. A good trade for small
  packages.
- `-ffp-contract=off` matches the setting Box3D applies on its other
  platforms for cross-platform determinism; with it, all four builds
  above produce bit-identical simulation results (the ABI conformance
  hash and the drop example output are the same for every variant).
- An LTO static library contains LLVM bitcode, so the final application
  link must use `lld-link` (a drop-in replacement for `link`); the DLLs
  are ordinary native code usable anywhere.

`package.cmd` packages the generic `-O3` LTO builds by default and adds
the `-Oz` DLL as `shared\box3d-Oz.dll` when it exists; set
`B3_SHARED_DIR` and `B3_STATIC_DIR` to package a different flavor, e.g.
`build-shared`/`build-static` for the stock MSVC libraries (whose static
library then works with plain `link`).
