# Box3D bindings for fasm2

fasm2 includes for the Box3D C interface, for the default library build:
single precision (no `BOX3D_DOUBLE_PRECISION`), Windows x64, MSVC layout.

| File | Purpose |
| --- | --- |
| `box3d.inc` | Constants, enums, and all public struct layouts (`struct`/`sizeof.`/field offsets). Requires fasm2's `macro/struct.inc`, which it includes itself. |
| `box3d.extrn.inc` | `extrn` declarations for all 578 `B3_API` functions, for `format MS64 COFF` objects linked against `box3d.lib` (static) or the `box3d.dll` import library. Only symbols you use are declared. |
| `box3d.api.inc` | Import list for `format PE64` executables importing `box3d.dll` directly with `macro/import64.inc` (no linker needed). Only symbols you use are imported. |

## Building the libraries

From the [repository root](https://github.com/erincatto/box3d), with Visual Studio and CMake:

```bat
rem static library -> build-static\src\Release\box3d.lib
cmake -S . -B build-static -G "Visual Studio 18 2026" -DBOX3D_SAMPLES=OFF -DBOX3D_UNIT_TESTS=OFF -DBUILD_SHARED_LIBS=OFF
cmake --build build-static --config Release --target box3d

rem DLL + import library -> build-shared\bin\Release\box3d.dll, build-shared\src\Release\box3d.lib
cmake -S . -B build-shared -G "Visual Studio 18 2026" -DBOX3D_SAMPLES=OFF -DBOX3D_UNIT_TESTS=OFF -DBUILD_SHARED_LIBS=ON
cmake --build build-shared --config Release --target box3d
```

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

## Layout verification

`test/` machine-checks every struct size, field offset, and integer constant
in `box3d.inc` against the C compiler:

```bat
cd bindings\fasm2\test
python gen_layout.py ..\box3d.inc gen_layout.c
cl /nologo /I..\..\..\include gen_layout.c
gen_layout.exe > layout_check.inc
fasm2 test_layout.asm
```

`gen_layout.py` parses `box3d.inc`, emits a C program that prints one fasmg
`assert` line per struct/field/constant using `sizeof`/`offsetof`, and
`test_layout.asm` assembles the bindings against that output. Any mismatch
fails assembly. Re-run this after pulling upstream header changes.

`test\run_tests.cmd` runs the layout check and builds and runs both examples
against the static library, the import library, and by direct DLL import.
