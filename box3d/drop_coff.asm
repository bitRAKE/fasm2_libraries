; Box3D fasm2 example: drop a sphere and print where it lands.
;
; Assembles to a COFF object that links against either flavor of the library:
;   fasm2 drop_coff.asm
;   link drop_coff.obj box3d.lib libcmt.lib legacy_stdio_definitions.lib
;
; Use static\box3d.lib for a static build, or
; dynamic\box3d.lib (import library) plus box3d.dll
; next to the executable for a dynamic build.

format MS64 COFF

include 'include/box3d.inc'
include 'include/box3d.extrn.inc'

public main
extrn printf

LOCALS = sizeof.b3WorldDef + sizeof.b3BodyDef + sizeof.b3ShapeDef \
       + sizeof.b3Sphere + sizeof.b3Pos + sizeof.b3Version
FRAME = (0x20 + LOCALS + 15) and (not 15)

virtual at rsp+0x20
  wdef b3WorldDef
  bdef b3BodyDef
  sdef b3ShapeDef
  sph  b3Sphere
  pos  b3Pos
  ver  b3Version
end virtual

section '.text' code readable executable

main:
        push    rbx
        push    rsi
        push    rdi
        sub     rsp,FRAME

        lea     rcx,[ver]               ; b3Version returned via hidden pointer
        call    b3GetVersion

        lea     rcx,[wdef]
        call    b3DefaultWorldDef
        lea     rcx,[wdef]
        call    b3CreateWorld
        mov     ebx,eax                 ; b3WorldId fits in a register

        lea     rcx,[bdef]
        call    b3DefaultBodyDef
        mov     dword [bdef.type],b3_dynamicBody
        mov     eax,[ten]
        mov     [bdef.position.y],eax   ; start 10m up
        mov     ecx,ebx
        lea     rdx,[bdef]
        call    b3CreateBody
        mov     rsi,rax                 ; b3BodyId fits in a register

        lea     rcx,[sdef]
        call    b3DefaultShapeDef
        xor     eax,eax
        mov     [sph.center.x],eax
        mov     [sph.center.y],eax
        mov     [sph.center.z],eax
        mov     eax,[half]
        mov     [sph.radius],eax
        mov     rcx,rsi
        lea     rdx,[sdef]
        lea     r8,[sph]
        call    b3CreateSphereShape

        mov     edi,90                  ; 1.5 seconds of free fall
  .step:
        mov     ecx,ebx
        movss   xmm1,[timeStep]
        mov     r8d,4
        call    b3World_Step
        dec     edi
        jnz     .step

        lea     rcx,[pos]               ; b3Pos returned via hidden pointer
        mov     rdx,rsi
        call    b3Body_GetPosition

        mov     ecx,ebx
        call    b3DestroyWorld

        lea     rcx,[fmt]
        mov     edx,[ver.major]
        mov     r8d,[ver.minor]
        mov     r9d,[ver.revision]
        cvtss2sd xmm0,[pos.y]
        movsd   [rsp+0x20],xmm0         ; fifth printf argument on the stack
        call    printf

        xor     eax,eax
        add     rsp,FRAME
        pop     rdi
        pop     rsi
        pop     rbx
        ret

section '.rdata' data readable

fmt  db 'Box3D %d.%d.%d: sphere dropped from y = 10 is at y = %.3f after 90 steps',10,0
timeStep dd 1.0/60.0
half dd 0.5
ten  dd 10.0
