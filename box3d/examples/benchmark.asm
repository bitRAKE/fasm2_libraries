; Box3D fasm2 example: multithreaded stress test, 49600 boxes.
;
;   fasm2 benchmark.asm
;
; Run with box3d.dll (from the distribution's shared directory) next to
; the executable.
; 49600 boxes rain into a pile with sleeping enabled, so settled islands
; drop out of the solver and the awake count in the title bar falls as the
; pile calms down. Box3D runs its own internal scheduler on worker
; threads; this program only sets b3WorldDef.workerCount.
;   + / -  raise or lower the solver worker count (watch the step time)
;   ] / [  raise or lower the sub-step count (solver accuracy vs speed)
;   SPACE  detonate an explosion under the pile (wakes everything)
;   R      rebuild the scene
;   ESC    quit
; The title bar shows live counters: bodies, awake bodies, touching
; contacts, workers, physics step time from b3World_GetProfile, and
; frames per second.
;
; Rendering is fully instanced so the draw cost stays flat as the body
; count grows. Each body's userData holds its slot in a CPU instance
; array (position, quaternion, half extents, color). After each step, one
; b3World_GetBodyEvents call returns every moved body with its new
; transform in a contiguous array and a tight copy loop refreshes the
; touched slots. No per-body API calls.
;
; The GPU side uses a persistently mapped buffer (GL 4.4 buffer storage,
; coherent write mapping): the CPU array is copied straight into one of
; three regions of GPU-visible memory, with glFenceSync guarding region
; reuse, and the scene draws with a single instanced call whose base
; instance selects the region. No glBufferData respecification, no driver
; staging copy.
;
; Window and OpenGL setup follow fasm2's examples/opengl/opengl.asm.

format PE64 NX GUI 5.0
entry start

include 'win64a.inc'
include 'box3d.inc'

WGL_CONTEXT_MAJOR_VERSION_ARB	:= 0x2091
WGL_CONTEXT_MINOR_VERSION_ARB	:= 0x2092

GL_DEPTH_BUFFER_BIT	:= 0x00000100
GL_COLOR_BUFFER_BIT	:= 0x00004000
GL_DEPTH_TEST		:= 0x0B71
GL_TRIANGLES		:= 0x0004
GL_FLOAT		:= 0x1406
GL_ARRAY_BUFFER 	:= 0x8892
GL_STATIC_DRAW		:= 0x88E4
GL_VERTEX_SHADER	:= 0x8B31
GL_FRAGMENT_SHADER	:= 0x8B30
GL_MAP_WRITE_BIT	:= 0x0002
GL_MAP_PERSISTENT_BIT	:= 0x0040
GL_MAP_COHERENT_BIT	:= 0x0080
GL_SYNC_GPU_COMMANDS_COMPLETE := 0x9117
GL_SYNC_FLUSH_COMMANDS_BIT := 0x00000001

; VK_ADD and VK_SUBTRACT (numpad) come from the win64a equates
VK_OEM_PLUS		:= 0xBB 	; '=' / '+' main row
VK_OEM_MINUS		:= 0xBD 	; '-' main row
VK_OEM_4		:= 0xDB 	; '['
VK_OEM_6		:= 0xDD 	; ']'

MAX_SUBSTEPS		:= 16

GRID			:= 40		; boxes per side in each layer
LAYERS			:= 31		; layers in the spawn grid
MAX_BODIES		:= GRID*GRID*LAYERS

; instance record: pos vec3, quat vec4, half vec3, color vec3
INST_SIZE		:= 52
MAX_INSTANCES		:= MAX_BODIES + 1	; instance 0 is the ground slab
REGION_SIZE		:= MAX_INSTANCES*INST_SIZE
REGION_COUNT		:= 3

iterate name,\
	glCreateShader,\
	glShaderSource,\
	glCompileShader,\
	glCreateProgram,\
	glAttachShader,\
	glLinkProgram,\
	glDeleteShader,\
	glGenVertexArrays,\
	glBindVertexArray,\
	glGenBuffers,\
	glBindBuffer,\
	glBufferData,\
	glVertexAttribPointer,\
	glEnableVertexAttribArray,\
	glVertexAttribDivisor,\
	glBufferStorage,\
	glMapBufferRange,\
	glFenceSync,\
	glClientWaitSync,\
	glDeleteSync,\
	glDrawArraysInstancedBaseInstance,\
	glUseProgram,\
	glGetUniformLocation,\
	glUniform1f

	define CONTEXT_AWARE_FUNCTION name

end iterate

; one cube face: normal followed by four corners, as two CCW triangles
macro quad nx,ny,nz, x0,y0,z0, x1,y1,z1, x2,y2,z2, x3,y3,z3
	dd x0,y0,z0, nx,ny,nz
	dd x1,y1,z1, nx,ny,nz
	dd x2,y2,z2, nx,ny,nz
	dd x0,y0,z0, nx,ny,nz
	dd x2,y2,z2, nx,ny,nz
	dd x3,y3,z3, nx,ny,nz
end macro

section '.data' data readable writeable

  wc WNDCLASS style:0, lpfnWndProc:WindowProc, lpszClassName:_class

  attribs:	; persistent buffer mapping needs GL 4.4 buffer storage
	dd WGL_CONTEXT_MAJOR_VERSION_ARB, 4
	dd WGL_CONTEXT_MINOR_VERSION_ARB, 4
	dd 0

  cube_vertices:
	quad  1.0, 0.0, 0.0,   1.0,-1.0,-1.0,   1.0, 1.0,-1.0,   1.0, 1.0, 1.0,   1.0,-1.0, 1.0
	quad -1.0, 0.0, 0.0,  -1.0,-1.0, 1.0,  -1.0, 1.0, 1.0,  -1.0, 1.0,-1.0,  -1.0,-1.0,-1.0
	quad  0.0, 1.0, 0.0,  -1.0, 1.0,-1.0,  -1.0, 1.0, 1.0,   1.0, 1.0, 1.0,   1.0, 1.0,-1.0
	quad  0.0,-1.0, 0.0,  -1.0,-1.0, 1.0,  -1.0,-1.0,-1.0,   1.0,-1.0,-1.0,   1.0,-1.0, 1.0
	quad  0.0, 0.0, 1.0,  -1.0,-1.0, 1.0,   1.0,-1.0, 1.0,   1.0, 1.0, 1.0,  -1.0, 1.0, 1.0
	quad  0.0, 0.0,-1.0,   1.0,-1.0,-1.0,  -1.0,-1.0,-1.0,  -1.0, 1.0,-1.0,   1.0, 1.0,-1.0

  align 8

  p_vs_src dq vs_src
  p_fs_src dq fs_src

  hdc dq ?
  hrc dq ?

  clock dq ?

  msg MSG
  rc RECT
  pfd PIXELFORMATDESCRIPTOR
  sysinfo SYSTEM_INFO

  wglCreateContextAttribsARB dq ?

  irpv name, CONTEXT_AWARE_FUNCTION
	name dq ?
  end irpv

  vs_id dd ?
  fs_id dd ?
  program dd ?
  vao dd ?
  vbo dd ?
  vboInst dd ?

  uAspectLoc dd ?

  ; Box3D state
  align 8
  wdef b3WorldDef
  bdef b3BodyDef
  sdef b3ShapeDef
  edef b3ExplosionDef
  counters b3Counters
  prof b3Profile
  bevents b3BodyEvents
  cubeHull b3BoxHull
  groundHull b3BoxHull

  bodyCount dd ?
  instCount dd ?
  world dd ?			; b3WorldId; null while index1 (low word) is zero
  workers dd ?
  maxWorkers dd ?
  subSteps dd 4			; recommended default
  rngSeed dd 0x12345678
  layerY dd ?

  ; persistent mapping ring
  align 8
  instPtr dq ?			; persistently mapped GPU pointer
  fences dq REGION_COUNT dup 0
  frameIndex dd 0
  curRegion dd ?
  baseInst dd ?

  ; HUD state
  frames dd ?
  fps dd ?
  fpsTick dd ?
  msInt dd ?
  msFrac dd ?
  awake dd ?
  titleBuf rb 256

  ; persistent instance buffer, refreshed in place from move events
  align 16
  instbuf rb MAX_INSTANCES*INST_SIZE

section '.text' code readable executable

  start:
	sub	rsp,8
	invoke	GetModuleHandle,0
	mov	[wc.hInstance],rax
	invoke	LoadIcon,0,IDI_APPLICATION
	mov	[wc.hIcon],rax
	invoke	LoadCursor,0,IDC_ARROW
	mov	[wc.hCursor],rax

	; worker limits: key 0 uses every logical processor (capped to Box3D's
	; B3_MAX_WORKERS); the startup default is half of that
	invoke	GetSystemInfo,addr sysinfo
	mov	eax,[sysinfo.dwNumberOfProcessors]
	test	eax,eax
	jnz	@f
	mov	eax,1
    @@:
	cmp	eax,B3_MAX_WORKERS
	jbe	@f
	mov	eax,B3_MAX_WORKERS
    @@:
	mov	[maxWorkers],eax
	shr	eax,1
	test	eax,eax
	jnz	@f
	mov	eax,1
    @@:
	mov	[workers],eax

	invoke	RegisterClass,wc
	invoke	CreateWindowEx,0,_class,_class,WS_VISIBLE+WS_OVERLAPPEDWINDOW+WS_CLIPCHILDREN+WS_CLIPSIBLINGS,64,64,1120,700,NULL,NULL,[wc.hInstance],NULL

  msg_loop:
	invoke	GetMessage,addr msg,NULL,0,0
	cmp	eax,1
	jb	end_loop
	jne	msg_loop
	invoke	TranslateMessage,addr msg
	invoke	DispatchMessage,addr msg
	jmp	msg_loop

  end_loop:
	invoke	ExitProcess,[msg.wParam]

proc WindowProc uses rbx rsi rdi, hwnd,wmsg,wparam,lparam

	mov	[hwnd],rcx
	cmp	edx,WM_CREATE
	je	wmcreate
	cmp	edx,WM_SIZE
	je	wmsize
	cmp	edx,WM_PAINT
	je	wmpaint
	cmp	edx,WM_KEYDOWN
	je	wmkeydown
	cmp	edx,WM_DESTROY
	je	wmdestroy
  defwndproc:
	invoke	DefWindowProc,rcx,rdx,r8,r9
	jmp	finish
  wmcreate:
	invoke	GetDC,rcx
	mov	[hdc],rax
	lea	rdi,[pfd]
	mov	rcx,sizeof.PIXELFORMATDESCRIPTOR shr 3
	xor	eax,eax
	rep	stosq
	mov	[pfd.nSize],sizeof.PIXELFORMATDESCRIPTOR
	mov	[pfd.nVersion],1
	mov	[pfd.dwFlags],PFD_SUPPORT_OPENGL+PFD_DOUBLEBUFFER+PFD_DRAW_TO_WINDOW
	mov	[pfd.iLayerType],PFD_MAIN_PLANE
	mov	[pfd.iPixelType],PFD_TYPE_RGBA
	mov	[pfd.cColorBits],32
	mov	[pfd.cAlphaBits],8
	mov	[pfd.cDepthBits],24
	mov	[pfd.cStencilBits],8
	invoke	ChoosePixelFormat,[hdc],addr pfd
	invoke	SetPixelFormat,[hdc],eax,addr pfd

	invoke	wglCreateContext,[hdc]
	test	rax,rax
	jz	context_not_created
	mov	[hrc],rax
	invoke	wglMakeCurrent,[hdc],[hrc]

	lea	rbx,[_wglCreateContextAttribsARB]	; name pointer in rbx for error handler
	invoke	wglGetProcAddress,rbx
	test	rax,rax
	jz	function_not_supported
	mov	[wglCreateContextAttribsARB],rax

	invoke	wglDeleteContext,[hrc]
	invoke	wglCreateContextAttribsARB,[hdc],0,attribs
	test	rax,rax
	jz	context_not_created
	mov	[hrc],rax
	invoke	wglMakeCurrent,[hdc],[hrc]

  irpv name, CONTEXT_AWARE_FUNCTION
	lea	rbx,[_#name]				; name pointer in rbx for error handler
	invoke	wglGetProcAddress,rbx
	test	rax,rax
	jz	function_not_supported
	mov	[name],rax
  end irpv

	invoke	glCreateShader,GL_VERTEX_SHADER
	mov	[vs_id],eax
	invoke	glShaderSource,[vs_id],1,addr p_vs_src,0
	invoke	glCompileShader,[vs_id]

	invoke	glCreateShader,GL_FRAGMENT_SHADER
	mov	[fs_id],eax
	invoke	glShaderSource,[fs_id],1,addr p_fs_src,0
	invoke	glCompileShader,[fs_id]

	invoke	glCreateProgram
	mov	[program],eax

	invoke	glAttachShader,[program],[vs_id]
	invoke	glAttachShader,[program],[fs_id]

	invoke	glLinkProgram,[program]

	invoke	glDeleteShader,[vs_id]
	invoke	glDeleteShader,[fs_id]

	invoke	glUseProgram,[program]

	invoke	glGetUniformLocation,[program],uAspect
	mov	[uAspectLoc],eax

	invoke	glGenVertexArrays,1,addr vao
	invoke	glBindVertexArray,[vao]

	; per-vertex cube geometry
	invoke	glGenBuffers,1,addr vbo
	invoke	glBindBuffer,GL_ARRAY_BUFFER,[vbo]
	invoke	glBufferData,GL_ARRAY_BUFFER,36*6*4,addr cube_vertices,GL_STATIC_DRAW

	invoke	glVertexAttribPointer,0,3,GL_FLOAT,0,24,0	; position
	invoke	glEnableVertexAttribArray,0
	invoke	glVertexAttribPointer,1,3,GL_FLOAT,0,24,12	; normal
	invoke	glEnableVertexAttribArray,1

	; per-instance body data: immutable storage, persistently and
	; coherently mapped for the life of the program, three regions deep
	invoke	glGenBuffers,1,addr vboInst
	invoke	glBindBuffer,GL_ARRAY_BUFFER,[vboInst]
	invoke	glBufferStorage,GL_ARRAY_BUFFER,REGION_COUNT*REGION_SIZE,0,\
			GL_MAP_WRITE_BIT+GL_MAP_PERSISTENT_BIT+GL_MAP_COHERENT_BIT
	invoke	glMapBufferRange,GL_ARRAY_BUFFER,0,REGION_COUNT*REGION_SIZE,\
			GL_MAP_WRITE_BIT+GL_MAP_PERSISTENT_BIT+GL_MAP_COHERENT_BIT
	test	rax,rax
	jz	map_failed
	mov	[instPtr],rax

	invoke	glVertexAttribPointer,2,3,GL_FLOAT,0,INST_SIZE,0	; iPos
	invoke	glEnableVertexAttribArray,2
	invoke	glVertexAttribDivisor,2,1
	invoke	glVertexAttribPointer,3,4,GL_FLOAT,0,INST_SIZE,12	; iQuat
	invoke	glEnableVertexAttribArray,3
	invoke	glVertexAttribDivisor,3,1
	invoke	glVertexAttribPointer,4,3,GL_FLOAT,0,INST_SIZE,28	; iHalf
	invoke	glEnableVertexAttribArray,4
	invoke	glVertexAttribDivisor,4,1
	invoke	glVertexAttribPointer,5,3,GL_FLOAT,0,INST_SIZE,40	; iColor
	invoke	glEnableVertexAttribArray,5
	invoke	glVertexAttribDivisor,5,1

	invoke	glEnable,GL_DEPTH_TEST

	call	build_world

  wmsize:
	invoke	GetClientRect,[hwnd],addr rc
	invoke	glViewport,0,0,[rc.right],[rc.bottom]
	mov	eax,[rc.bottom]
	test	eax,eax
	jz	finish
	cvtsi2ss xmm1,[rc.right]
	cvtsi2ss xmm2,[rc.bottom]
	divss	xmm1,xmm2
	invoke	glUniform1f,[uAspectLoc],float xmm1
	xor	eax,eax
	jmp	finish
  wmpaint:
	invoke	GetTickCount
	mov	rcx,rax
	sub	rcx,[clock]
	cmp	rcx,15		; wait at least 15ms before stepping again
	jb	finish
	mov	[clock],rax

	invoke	b3World_Step,[world],float dword [timeStep],[subSteps]

	; refresh the instance slots of every body that moved: one API call,
	; then a contiguous copy loop (the move event transform layout matches
	; the instance buffer pos+quat layout, 28 bytes)
	invoke	b3World_GetBodyEvents,addr bevents,[world]
	mov	rsi,[bevents.moveEvents]
	mov	ebx,[bevents.moveCount]
	test	ebx,ebx
	jz	.upload
  .move:
	mov	rax,[rsi+b3BodyMoveEvent.userData]	; instance slot index
	imul	rax,rax,INST_SIZE
	lea	rdi,[instbuf+rax]
	movups	xmm0,dqword [rsi+b3BodyMoveEvent.transform]
	movups	xmm1,dqword [rsi+b3BodyMoveEvent.transform+12]
	movups	[rdi],xmm0
	movups	[rdi+12],xmm1
	add	rsi,sizeof.b3BodyMoveEvent
	dec	ebx
	jnz	.move
  .upload:
	; pick the next mapped region; wait on its fence so the GPU is done
	; reading it from three frames ago before writing over it
	mov	eax,[frameIndex]
	xor	edx,edx
	mov	ecx,REGION_COUNT
	div	ecx
	mov	[curRegion],edx
	mov	eax,edx
	cmp	qword [fences+rax*8],0
	je	.no_fence
	invoke	glClientWaitSync,qword [fences+rax*8],GL_SYNC_FLUSH_COMMANDS_BIT,100000000
	mov	eax,[curRegion]
	invoke	glDeleteSync,qword [fences+rax*8]
	mov	eax,[curRegion]
	mov	qword [fences+rax*8],0
  .no_fence:
	; copy the CPU instance array straight into GPU-visible memory; the
	; coherent mapping needs no flush
	mov	eax,[curRegion]
	imul	rax,rax,REGION_SIZE
	mov	rdi,[instPtr]
	add	rdi,rax
	lea	rsi,[instbuf]
	mov	ecx,[instCount]
	imul	ecx,ecx,INST_SIZE
	rep	movsb

	; update the title bar counters once per second
	inc	dword [frames]
	mov	eax,dword [clock]
	sub	eax,[fpsTick]
	cmp	eax,1000
	jb	.no_hud
	mov	ecx,eax
	mov	eax,[frames]
	imul	eax,1000
	xor	edx,edx
	div	ecx
	mov	[fps],eax
	mov	eax,dword [clock]
	mov	[fpsTick],eax
	mov	dword [frames],0
	invoke	b3World_GetCounters,addr counters,[world]
	invoke	b3World_GetAwakeBodyCount,[world]
	mov	[awake],eax
	invoke	b3World_GetProfile,addr prof,[world]
	movss	xmm0,[prof.step]
	mulss	xmm0,[cHundred]
	cvtss2si eax,xmm0
	mov	ecx,100
	cdq
	idiv	ecx
	mov	[msInt],eax
	mov	[msFrac],edx
	invoke	wsprintf,addr titleBuf,addr _fmt,[counters.bodyCount],[awake],[counters.contactCount],[workers],[subSteps],[msInt],[msFrac],[fps]
	invoke	SetWindowText,[hwnd],addr titleBuf
  .no_hud:

	invoke	glClearColor,float dword 0.07,float dword 0.08,float dword 0.11,float dword 1.0
	invoke	glClear,GL_COLOR_BUFFER_BIT+GL_DEPTH_BUFFER_BIT

	; the base instance selects the ring region; fence it for reuse
	mov	eax,[curRegion]
	imul	eax,eax,MAX_INSTANCES
	mov	[baseInst],eax
	invoke	glDrawArraysInstancedBaseInstance,GL_TRIANGLES,0,36,[instCount],[baseInst]
	invoke	glFenceSync,GL_SYNC_GPU_COMMANDS_COMPLETE,0
	mov	ecx,[curRegion]
	mov	[fences+rcx*8],rax
	inc	dword [frameIndex]

	invoke	SwapBuffers,[hdc]
	xor	eax,eax
	jmp	finish
  wmkeydown:
	cmp	r8d,VK_ESCAPE
	je	wmdestroy
	cmp	r8d,VK_SPACE
	je	explode
	cmp	r8d,'R'
	je	.rebuild
	cmp	r8d,VK_OEM_PLUS
	je	.more_workers
	cmp	r8d,VK_ADD
	je	.more_workers
	cmp	r8d,VK_OEM_MINUS
	je	.fewer_workers
	cmp	r8d,VK_SUBTRACT
	je	.fewer_workers
	cmp	r8d,VK_OEM_6
	je	.more_substeps
	cmp	r8d,VK_OEM_4
	je	.fewer_substeps
	jmp	defwndproc
  .more_workers:
	mov	ecx,[workers]
	cmp	ecx,[maxWorkers]
	jae	.done_key
	inc	ecx
	jmp	.set_workers
  .fewer_workers:
	mov	ecx,[workers]
	cmp	ecx,1
	jbe	.done_key
	dec	ecx
  .set_workers:
	mov	[workers],ecx
	invoke	b3World_SetWorkerCount,[world],[workers]
	jmp	.done_key
  .more_substeps:
	cmp	dword [subSteps],MAX_SUBSTEPS
	jae	.done_key
	inc	dword [subSteps]
	jmp	.done_key
  .fewer_substeps:
	cmp	dword [subSteps],1
	jbe	.done_key
	dec	dword [subSteps]
  .done_key:
	xor	eax,eax
	jmp	finish
  .rebuild:
	call	build_world
	xor	eax,eax
	jmp	finish
  explode:
	invoke	b3DefaultExplosionDef,addr edef
	xor	eax,eax
	mov	[edef.position.x],eax
	mov	[edef.position.z],eax
	mov	eax,[cExpHeight]
	mov	[edef.position.y],eax
	mov	eax,[cExpRadius]
	mov	[edef.radius],eax
	mov	eax,[cExpFalloff]
	mov	[edef.falloff],eax
	mov	eax,[cExpImpulse]
	mov	[edef.impulsePerArea],eax
	invoke	b3World_Explode,[world],addr edef
	xor	eax,eax
	jmp	finish
  wmdestroy:
	cmp	word [world],0
	je	.no_world
	invoke	b3DestroyWorld,[world]
	mov	dword [world],0
  .no_world:
	invoke	wglMakeCurrent,0,0
	invoke	wglDeleteContext,[hrc]
  exit:
	invoke	ReleaseDC,[hwnd],[hdc]
	invoke	PostQuitMessage,0
	xor	eax,eax
  finish:
	ret
  function_not_supported:
	invoke	MessageBox,[hwnd],_function_not_supported,rbx,MB_ICONERROR+MB_OK
	jmp	exit
  context_not_created:
	invoke	MessageBox,[hwnd],_context_not_created,NULL,MB_ICONERROR+MB_OK
	jmp	exit
  map_failed:
	invoke	MessageBox,[hwnd],_map_failed,NULL,MB_ICONERROR+MB_OK
	jmp	exit

endp

; xorshift32; returns a float in [-0.25, 0.25] in xmm0
proc rand_jitter
	mov	eax,[rngSeed]
	mov	ecx,eax
	shl	ecx,13
	xor	eax,ecx
	mov	ecx,eax
	shr	ecx,17
	xor	eax,ecx
	mov	ecx,eax
	shl	ecx,5
	xor	eax,ecx
	mov	[rngSeed],eax
	and	eax,0xFFFF
	cvtsi2ss xmm0,eax
	mulss	xmm0,[cJitterScale]
	subss	xmm0,[cJitterHalf]
	ret
endp

; (re)create the world: a big static ground box and a tall grid of cubes
; with jittered positions and rotations so the pile collapses into massive
; contact. Every body's instance slot is written here; after this only the
; pos+quat part is refreshed from move events.
proc build_world uses rbx rsi rdi

	cmp	word [world],0
	je	.fresh
	invoke	b3DestroyWorld,[world]
  .fresh:
	mov	dword [bodyCount],0

	invoke	b3DefaultWorldDef,addr wdef	; returned via hidden pointer
	mov	eax,[workers]
	mov	[wdef.workerCount],eax		; Box3D spawns its own scheduler threads
	; sleeping stays enabled: settled islands leave the solver and the
	; move-event stream, and the awake counter in the HUD tracks it
	invoke	b3CreateWorld,addr wdef
	mov	[world],eax

	invoke	b3MakeBoxHull,addr cubeHull,float dword [cHalf],float dword [cHalf],float dword [cHalf]
	invoke	b3MakeBoxHull,addr groundHull,float dword [cGroundHX],float dword [cHalf],float dword [cGroundHX]

	invoke	b3DefaultShapeDef,addr sdef

	; static ground, top surface at y = 0; instance slot 0, never refreshed
	invoke	b3DefaultBodyDef,addr bdef
	mov	eax,[cMinusHalf]
	mov	[bdef.position.y],eax
	invoke	b3CreateBody,[world],addr bdef
	invoke	b3CreateHullShape,rax,addr sdef,addr groundHull

	lea	rdx,[instbuf]
	xor	eax,eax
	mov	[rdx],eax			; pos = (0, -0.5, 0)
	mov	ecx,[cMinusHalf]
	mov	[rdx+4],ecx
	mov	[rdx+8],eax
	mov	[rdx+12],eax			; quat = identity
	mov	[rdx+16],eax
	mov	[rdx+20],eax
	mov	ecx,[cOne]
	mov	[rdx+24],ecx
	mov	ecx,[cGroundHX]
	mov	[rdx+28],ecx			; half = (hx, 0.5, hx)
	mov	ecx,[cHalf]
	mov	[rdx+32],ecx
	mov	ecx,[cGroundHX]
	mov	[rdx+36],ecx
	mov	ecx,[groundColor]
	mov	[rdx+40],ecx
	mov	ecx,[groundColor+4]
	mov	[rdx+44],ecx
	mov	ecx,[groundColor+8]
	mov	[rdx+48],ecx

	; spawn grid of dynamic cubes
	mov	dword [bdef.type],b3_dynamicBody
	xor	ebx,ebx 			; rbx = layer
  .layer:
	cvtsi2ss xmm0,ebx			; y = base + layer*spacing
	mulss	xmm0,[cSpacingY]
	addss	xmm0,[cBaseY]
	movss	[layerY],xmm0
	xor	esi,esi 			; rsi = x index
  .ix:
	xor	edi,edi 			; rdi = z index
  .iz:
	call	rand_jitter			; jitter y a little too
	movss	xmm1,[layerY]
	addss	xmm1,xmm0
	movss	[bdef.position.y],xmm1
	cvtsi2ss xmm1,esi
	mulss	xmm1,[cSpacing]
	subss	xmm1,[cGridHalfSpan]
	call	rand_jitter
	addss	xmm1,xmm0
	movss	[bdef.position.x],xmm1
	cvtsi2ss xmm1,edi
	mulss	xmm1,[cSpacing]
	subss	xmm1,[cGridHalfSpan]
	call	rand_jitter
	addss	xmm1,xmm0
	movss	[bdef.position.z],xmm1
	; random initial tilt so the stack collapses instead of settling:
	; normalize (jx, jy, jz, 1) into a valid rotation quaternion
	call	rand_jitter
	movss	xmm3,xmm0
	call	rand_jitter
	movss	xmm4,xmm0
	call	rand_jitter
	movss	xmm5,xmm0
	movss	xmm1,xmm3
	mulss	xmm1,xmm3
	movss	xmm0,xmm4
	mulss	xmm0,xmm4
	addss	xmm1,xmm0
	movss	xmm0,xmm5
	mulss	xmm0,xmm5
	addss	xmm1,xmm0
	addss	xmm1,[cOne]
	sqrtss	xmm1,xmm1
	divss	xmm3,xmm1
	divss	xmm4,xmm1
	divss	xmm5,xmm1
	movss	xmm0,[cOne]
	divss	xmm0,xmm1
	movss	[bdef.rotation.v.x],xmm3
	movss	[bdef.rotation.v.y],xmm4
	movss	[bdef.rotation.v.z],xmm5
	movss	[bdef.rotation.s],xmm0

	; instance slot index = body index + 1, carried in the body userData
	mov	eax,[bodyCount]
	inc	eax
	mov	dword [bdef.userData],eax
	mov	dword [bdef.userData+4],0

	; write the full instance record; b3BodyDef position and rotation are
	; contiguous 28 bytes, same layout as the instance pos+quat
	mov	ecx,eax
	imul	rcx,rcx,INST_SIZE
	lea	rdx,[instbuf+rcx]
	movups	xmm1,dqword [bdef.position]
	movups	xmm2,dqword [bdef.position+12]
	movups	[rdx],xmm1
	movups	[rdx+12],xmm2
	mov	eax,[cHalf]
	mov	[rdx+28],eax
	mov	[rdx+32],eax
	mov	[rdx+36],eax
	mov	eax,[bodyCount]
	and	eax,7
	lea	ecx,[eax+eax*2]
	mov	eax,[palette+rcx*4]
	mov	[rdx+40],eax
	mov	eax,[palette+rcx*4+4]
	mov	[rdx+44],eax
	mov	eax,[palette+rcx*4+8]
	mov	[rdx+48],eax

	invoke	b3CreateBody,[world],addr bdef
	inc	dword [bodyCount]
	invoke	b3CreateHullShape,rax,addr sdef,addr cubeHull
	inc	edi
	cmp	edi,GRID
	jb	.iz
	inc	esi
	cmp	esi,GRID
	jb	.ix
	inc	ebx
	cmp	ebx,LAYERS
	jb	.layer

	mov	eax,[bodyCount]
	inc	eax
	mov	[instCount],eax

	ret

endp

section '.rdata' data readable

  _class db 'BOX3DBENCH',0

  _fmt db 'Box3D fasm2 bench  bodies=%d awake=%d contacts=%d workers=%d sub=%d step=%d.%02dms fps=%d  [+/-: workers, [/]: substeps, SPACE: explode, R: reset]',0

  _function_not_supported db 'Function not supported.',0
  _context_not_created db 'Failed to create OpenGL 4.4 context.',0
  _map_failed db 'Failed to map the instance buffer.',0

  _wglCreateContextAttribsARB db 'wglCreateContextAttribsARB',0

  irpv name, CONTEXT_AWARE_FUNCTION
	_#name db `name,0
  end irpv

  vs_src file 'benchmark_vs.glsl'
	 db 0

  fs_src file 'benchmark_fs.glsl'
	 db 0

  uAspect db 'uAspect',0

  timeStep	dd 1.0/60.0
  cHalf 	dd 0.5
  cMinusHalf	dd -0.5
  cGroundHX	dd 100.0
  cSpacing	dd 1.1		; grid pitch of the spawn columns
  cGridHalfSpan dd (GRID-1)*1.1/2
  cBaseY	dd 0.6		; first layer floats just above the ground
  cSpacingY	dd 1.1
  cHundred	dd 100.0
  cOne		dd 1.0
  cJitterScale	dd 0.5/65536.0
  cJitterHalf	dd 0.25

  ; default shape density is 1000 kg/m^3, so each cube weighs a tonne;
  ; the impulse has to be sized accordingly
  cExpHeight	dd 3.0
  cExpRadius	dd 35.0
  cExpFalloff	dd 18.0
  cExpImpulse	dd 8000.0

  groundColor	dd 0.33, 0.35, 0.38

  palette:	; 8 body colors, matched to the Box2D brand colors and friends
	dd 0.86, 0.19, 0.20 	; red
	dd 0.19, 0.68, 0.75 	; blue
	dd 0.55, 0.79, 0.14 	; green
	dd 1.00, 0.93, 0.55 	; yellow
	dd 1.00, 0.65, 0.00 	; orange
	dd 0.58, 0.44, 0.86 	; purple
	dd 1.00, 0.41, 0.71 	; pink
	dd 0.13, 0.70, 0.67 	; teal

  align 8

  data import

  library kernel,'KERNEL32.DLL',\
	  user,'USER32.DLL',\
	  gdi,'GDI32.DLL',\
	  opengl,'OPENGL32.DLL',\
	  box3d,'box3d.dll'

  import kernel,\
	 GetModuleHandle,'GetModuleHandleA',\
	 GetTickCount,'GetTickCount',\
	 GetSystemInfo,'GetSystemInfo',\
	 ExitProcess,'ExitProcess'

  import user,\
	 MessageBox,'MessageBoxA',\
	 RegisterClass,'RegisterClassA',\
	 CreateWindowEx,'CreateWindowExA',\
	 DefWindowProc,'DefWindowProcA',\
	 GetMessage,'GetMessageA',\
	 TranslateMessage,'TranslateMessage',\
	 DispatchMessage,'DispatchMessageA',\
	 LoadCursor,'LoadCursorA',\
	 LoadIcon,'LoadIconA',\
	 GetClientRect,'GetClientRect',\
	 GetDC,'GetDC',\
	 ReleaseDC,'ReleaseDC',\
	 PostQuitMessage,'PostQuitMessage',\
	 SetWindowText,'SetWindowTextA',\
	 wsprintf,'wsprintfA'

  import gdi,\
	 ChoosePixelFormat,'ChoosePixelFormat',\
	 SetPixelFormat,'SetPixelFormat',\
	 SwapBuffers,'SwapBuffers'

  import opengl,\
	 glClear,'glClear',\
	 glClearColor,'glClearColor',\
	 glEnable,'glEnable',\
	 glViewport,'glViewport',\
	 glDrawArrays,'glDrawArrays',\
	 wglGetProcAddress,'wglGetProcAddress',\
	 wglCreateContext,'wglCreateContext',\
	 wglDeleteContext,'wglDeleteContext',\
	 wglMakeCurrent,'wglMakeCurrent'

  include 'box3d.api.inc'

  end data
