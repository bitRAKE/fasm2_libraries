# Box3D bindings for fasm2

fasm2 includes for the Box3D C interface, for the default library build:
single precision (no `BOX3D_DOUBLE_PRECISION`), Windows x64, MSVC layout.

| File | Purpose |
| --- | --- |
| `box3d.inc` | Constants, enums, and all public struct layouts (`struct`/`sizeof.`/field offsets). Requires fasm2's `macro/struct.inc`, which it includes itself. |
| `box3d.extrn.inc` | `extrn` declarations for all 578 `B3_API` functions, for `format MS64 COFF` objects linked against `box3d.lib` (static) or the `box3d.dll` import library. Only symbols you use are declared. |
| `box3d.api.inc` | Import list for `format PE64` executables importing `box3d.dll` directly with `macro/import64.inc` (no linker needed). Only symbols you use are imported. |

## Building the libraries

From the repository root, with Visual Studio and CMake:

```bat
rem static library -> build-static\src\Release\box3d.lib
cmake -S . -B build-static -G "Visual Studio 18 2026" -DBOX3D_SAMPLES=OFF -DBOX3D_UNIT_TESTS=OFF -DBUILD_SHARED_LIBS=OFF
cmake --build build-static --config Release --target box3d

rem DLL + import library -> build-shared\bin\Release\box3d.dll, build-shared\src\Release\box3d.lib
cmake -S . -B build-shared -G "Visual Studio 18 2026" -DBOX3D_SAMPLES=OFF -DBOX3D_UNIT_TESTS=OFF -DBUILD_SHARED_LIBS=ON
cmake --build build-shared --config Release --target box3d
```

### Optimized builds (native ISA + LTO)

VS ships clang-cl, lld-link, and Ninja, which support `-march=native` and
thin LTO while staying ABI-compatible with the MSVC builds (same struct
layout, same static CRT). From a vcvars64 prompt:

```bat
cmake -S . -B build-native-shared -G Ninja ^
  -DCMAKE_C_COMPILER=clang-cl -DCMAKE_CXX_COMPILER=clang-cl -DCMAKE_LINKER=lld-link ^
  -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON ^
  -DBOX3D_SAMPLES=OFF -DBOX3D_UNIT_TESTS=OFF ^
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON ^
  "-DCMAKE_C_FLAGS=/clang:-march=native /clang:-ffp-contract=off" ^
  "-DCMAKE_CXX_FLAGS=/clang:-march=native /clang:-ffp-contract=off"
cmake --build build-native-shared --target box3d
```

Swap `BUILD_SHARED_LIBS=OFF` and `build-native-static` for the static
variant. Notes:

- `-ffp-contract=off` matches the setting Box3D applies on its other
  platforms for cross-platform determinism; without it `-march=native`
  would fuse multiply-adds and change results. The fasm2 drop example
  reproduces the MSVC-build result exactly with these flags.
- The static library contains LLVM bitcode, so the final application link
  must use `lld-link` (a drop-in replacement for `link`); the DLL is
  ordinary native code usable anywhere.
- Measured on the benchmark example scene (2352 boxes, ~12.5k contacts):
  step time 8.5 -> 6.2 ms at 1 worker and 2.0 -> 1.4 ms at 8 workers
  versus the stock MSVC Release build, about 30% faster. Binaries built
  with `-march=native` only run on CPUs with the build machine's ISA.

## Using the bindings

COFF object linked by MSVC `link` (works with the static library or the
import library):

```asm
format MS64 COFF
include 'box3d.inc'
include 'box3d.extrn.inc'
...
call    b3CreateWorld
```

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

See `examples/drop_coff.asm` and `examples/drop_pe.asm` for complete,
runnable programs (a sphere in free fall).

Two OpenGL demos show the bindings driving a real simulation (assemble with
`fasm2`, run with `box3d.dll` next to the executable). Both render each body
as a unit cube that the vertex shader scales, rotates by the body
quaternion, and projects:

- `examples/pyramid.asm` -- a pyramid of 91 boxes, one draw call per body
  with the transform passed as uniforms (the simple path). SPACE detonates
  a `b3World_Explode` at the base, R rebuilds, ESC quits.
- `examples/benchmark.asm` -- a multithreaded stress test: 10000 boxes with
  randomized rotations collapse into a pile, with sleeping disabled for
  sustained solver load. Box3D runs its own internal scheduler; the program
  only sets `b3WorldDef.workerCount`. Keys 1-8 switch the worker count at
  runtime via `b3World_SetWorkerCount`, and the title bar shows live
  bodies/contacts/step-time/fps from `b3World_GetCounters` and
  `b3World_GetProfile`.

  The benchmark renders with zero per-body API calls: each body's userData
  holds its slot in a persistent instance buffer, one
  `b3World_GetBodyEvents` call returns every moved body's transform in a
  contiguous array, an SSE loop refreshes the touched slots, and the scene
  draws with a single `glDrawArraysInstanced` after one buffer upload.
  With the native+LTO library on the development machine the 10000-box
  scene steps in ~32 ms on 1 worker and ~6.4 ms on 8 workers (60 fps),
  including a full-scene explosion with every body awake.

## ABI notes

- The Windows x64 calling convention applies. Structs of 1, 2, 4, or 8
  bytes (`b3WorldId`, `b3BodyId`, `b3ShapeId`, `b3JointId`) pass and return
  by value in a GP register.
- Larger structs (`b3Vec3`, `b3Pos`, `b3Version`, `b3WorldDef`, ...) are
  passed by pointer to a caller-owned copy and *returned through a hidden
  pointer argument in RCX*, shifting the visible parameters right by one.
- `bool` is one byte; enums are 4 bytes (`dd`).
- `b3Pos`, `b3WorldTransform`, and `b3WorldCastOutput` are defined as their
  single precision layouts (`b3Vec3`/`b3Transform`/`b3CastOutput`), matching
  the C typedefs when `BOX3D_DOUBLE_PRECISION` is off. A double precision
  library build changes the ABI and is not covered by these includes.
- `b3InternalAssert` is declared in the headers but only exists in debug
  builds (or with `B3_ENABLE_ASSERT`); release `box3d.dll` does not export it.
- Three struct fields collide with fasm2 directive names and are declared
  with the `label name: type` idiom instead of a data definition:
  `b3CollisionPlane.push`, `b3MeshNode.data`, `b3Mesh.data`. Their offsets
  are unchanged; they are just not initializable in a struct literal.
