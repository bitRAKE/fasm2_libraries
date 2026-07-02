> [!WARNING]
> This software is work in progress. Keep your expectations low.

Please, be mindful of the LICENSE in each library folder. *Anything* not covered by that license is in the public domain.

# fasm2 libraries

Pre-built library addons and fasm2 include files for Windows x64 experiments.

## Libraries

| Library | Contents | Notes |
| --- | --- | --- |
| [`box3d/`](box3d/) | fasm2 bindings, import declarations, examples, and pre-built static/shared library artifacts for the [Box3D](https://github.com/erincatto/box3d) C API. | See [`box3d/README.md`](box3d/README.md) for ABI notes, build commands for the upstream CMake libraries, and layout-verification steps. |

## Repository layout

- `box3d/include/` contains the generated/hand-maintained fasm2 include files:
  - `box3d.inc` for constants and struct layouts.
  - `box3d.extrn.inc` for COFF objects linked with `box3d.lib`.
  - `box3d.api.inc` for PE64 executables importing `box3d.dll` directly.
- `box3d/static/` and `box3d/shared/` contain the pre-built Box3D library artifacts currently tracked in this repository.
- `box3d/drop_coff.asm`, `box3d/drop_pe.asm`, and `box3d/pyramid.asm` are small fasm2 examples that exercise the bindings.

## Verification

There is not currently a repository-wide Linux build command. The Box3D binding README documents the Windows/MSVC and fasm2 layout-check flow that should be run after pulling upstream Box3D header changes.
