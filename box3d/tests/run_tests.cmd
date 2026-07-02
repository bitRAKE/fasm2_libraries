@echo off
rem Box3D fasm2 bindings test suite. Runs from the distribution's tests
rem directory (include\, static\, and shared\ are siblings).
rem Prerequisites: fasm2 on PATH (or set FASM2), an MSVC environment
rem (vcvars64), and python.

setlocal
if "%FASM2%"=="" set FASM2=fasm2
rem the distribution's static library is LLVM bitcode (thin LTO), which
rem MSVC link cannot consume; prefer lld-link when available
if "%LINKER%"=="" (
    where lld-link >nul 2>&1 && (set LINKER=lld-link) || (set LINKER=link)
)
set DIST=%~dp0..
rem one include path serves fasm2 (the .inc bindings) and cl (the C headers)
set INCLUDE=%DIST%\include;%INCLUDE%

cd /d "%~dp0"

echo === layout check ===
python gen_layout.py "%DIST%\include\box3d.inc" gen_layout.c || exit /b 1
cl /nologo gen_layout.c || exit /b 1
.\gen_layout.exe > layout_check.inc || exit /b 1
call %FASM2% test_layout.asm || exit /b 1

echo === ABI conformance: C reference vs fasm2 bindings ===
cl /nologo api_check.c /link "%DIST%\shared\box3d.lib" /out:api_check_c.exe || exit /b 1
call %FASM2% api_check.asm || exit /b 1
%LINKER% /nologo /subsystem:console /LARGEADDRESSAWARE:NO /out:api_check_asm.exe api_check.obj ^
    "%DIST%\shared\box3d.lib" libcmt.lib legacy_stdio_definitions.lib || exit /b 1
copy /y "%DIST%\shared\box3d.dll" . >nul || exit /b 1
.\api_check_c.exe > api_c.txt || exit /b 1
.\api_check_asm.exe > api_asm.txt || exit /b 1
fc api_c.txt api_asm.txt >nul || (echo ABI conformance FAILED: hashes diverge & exit /b 1)
type api_asm.txt
echo ABI conformance passed: asm output matches the C reference bit for bit

echo === examples ===
cd /d "%DIST%\examples"
call %FASM2% drop_coff.asm || exit /b 1
call %FASM2% drop_pe.asm || exit /b 1
%LINKER% /nologo /subsystem:console /out:drop_static.exe drop_coff.obj ^
    "%DIST%\static\box3d.lib" libcmt.lib legacy_stdio_definitions.lib || exit /b 1
%LINKER% /nologo /subsystem:console /out:drop_shared.exe drop_coff.obj ^
    "%DIST%\shared\box3d.lib" libcmt.lib legacy_stdio_definitions.lib || exit /b 1
copy /y "%DIST%\shared\box3d.dll" . >nul || exit /b 1

echo --- static library:
.\drop_static.exe || exit /b 1
echo --- shared library, import library:
.\drop_shared.exe || exit /b 1
echo --- shared library, direct PE import:
.\drop_pe.exe || exit /b 1

echo === all fasm2 binding tests passed ===
