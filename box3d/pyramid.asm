; Box3D fasm2 example: a pyramid of 91 boxes, rendered with OpenGL 3.3.
;
;   fasm2 pyramid.asm
;
; Run with box3d.dll (build-shared\bin\Release) next to the executable.
;   SPACE  detonate an explosion at the base of the pyramid
;   R      rebuild the pyramid
;   ESC    quit
;
; The window and OpenGL setup follow fasm2's examples/opengl/opengl.asm.
; All rigid body math stays inside Box3D; each body is drawn as a unit cube
; that the vertex shader scales, rotates by the body quaternion, and
; projects, so the assembly side only shuttles uniforms.

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

PYRAMID_LEVELS := 11
MAX_BODIES := (PYRAMID_LEVELS*(PYRAMID_LEVELS+1)*(2*PYRAMID_LEVELS+1))/6

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
	glUseProgram,\
	glGetUniformLocation,\
	glUniform1f,\
	glUniform3f,\
	glUniform4f

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

  attribs:
	dd WGL_CONTEXT_MAJOR_VERSION_ARB, 3
	dd WGL_CONTEXT_MINOR_VERSION_ARB, 3
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

  wglCreateContextAttribsARB dq ?

  irpv name, CONTEXT_AWARE_FUNCTION
	name dq ?
  end irpv

  vs_id dd ?
  fs_id dd ?
  program dd ?
  vao dd ?
  vbo dd ?

  uPosLoc dd ?
  uQuatLoc dd ?
  uHalfLoc dd ?
  uColorLoc dd ?
  uAspectLoc dd ?

  ; Box3D state
  align 8
  wdef b3WorldDef
  bdef b3BodyDef
  sdef b3ShapeDef
  edef b3ExplosionDef
  cubeHull b3BoxHull
  groundHull b3BoxHull
  wt b3WorldTransform

  bodies rq MAX_BODIES		; dynamic body ids
  bodyCount dd ?
  world dd ?			; b3WorldId; null while index1 (low word) is zero
  nSide dd ?
  halfSpan dd ?

section '.text' code readable executable

  start:
	sub	rsp,8
	invoke	GetModuleHandle,0
	mov	[wc.hInstance],rax
	invoke	LoadIcon,0,IDI_APPLICATION
	mov	[wc.hIcon],rax
	invoke	LoadCursor,0,IDC_ARROW
	mov	[wc.hCursor],rax
	invoke	RegisterClass,wc
	invoke	CreateWindowEx,0,_class,_title,WS_VISIBLE+WS_OVERLAPPEDWINDOW+WS_CLIPCHILDREN+WS_CLIPSIBLINGS,64,64,960,640,NULL,NULL,[wc.hInstance],NULL

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

	invoke	glGetUniformLocation,[program],uPos
	mov	[uPosLoc],eax
	invoke	glGetUniformLocation,[program],uQuat
	mov	[uQuatLoc],eax
	invoke	glGetUniformLocation,[program],uHalf
	mov	[uHalfLoc],eax
	invoke	glGetUniformLocation,[program],uColor
	mov	[uColorLoc],eax
	invoke	glGetUniformLocation,[program],uAspect
	mov	[uAspectLoc],eax

	invoke	glGenVertexArrays,1,addr vao
	invoke	glBindVertexArray,[vao]

	invoke	glGenBuffers,1,addr vbo
	invoke	glBindBuffer,GL_ARRAY_BUFFER,[vbo]

	invoke	glBufferData,GL_ARRAY_BUFFER,36*6*4,addr cube_vertices,GL_STATIC_DRAW

	invoke	glVertexAttribPointer,\ ; position
			0,\		; index, layout(location=0)
			3,\		; size(vec3)
			GL_FLOAT,\	; type
			0,\		; normalized
			24,\		; stride(bytes)
			0		; offset(bytes)
	invoke	glEnableVertexAttribArray,0

	invoke	glVertexAttribPointer,\ ; normal
			1,\		; index, layout(location=1)
			3,\		; size(vec3)
			GL_FLOAT,\	; type
			0,\		; normalized
			24,\		; stride(bytes)
			12		; offset(bytes), skip position
	invoke	glEnableVertexAttribArray,1

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

	invoke	b3World_Step,[world],float dword [timeStep],4

	invoke	glClearColor,float dword 0.07,float dword 0.08,float dword 0.11,float dword 1.0
	invoke	glClear,GL_COLOR_BUFFER_BIT+GL_DEPTH_BUFFER_BIT

	; ground slab, static at y = -0.5 with identity rotation
	invoke	glUniform3f,[uPosLoc],float dword 0.0,float dword -0.5,float dword 0.0
	invoke	glUniform4f,[uQuatLoc],float dword 0.0,float dword 0.0,float dword 0.0,float dword 1.0
	invoke	glUniform3f,[uHalfLoc],float dword [cGroundHX],float dword [cHalf],float dword [cGroundHX]
	invoke	glUniform3f,[uColorLoc],float dword 0.33,float dword 0.35,float dword 0.38
	invoke	glDrawArrays,GL_TRIANGLES,0,36

	invoke	glUniform3f,[uHalfLoc],float dword [cHalf],float dword [cHalf],float dword [cHalf]

	xor	ebx,ebx
  .body:
	invoke	b3Body_GetTransform,addr wt,[bodies+rbx*8]
	invoke	glUniform3f,[uPosLoc],float dword [wt.p.x],float dword [wt.p.y],float dword [wt.p.z]
	invoke	glUniform4f,[uQuatLoc],float dword [wt.q.v.x],float dword [wt.q.v.y],float dword [wt.q.v.z],float dword [wt.q.s]
	mov	eax,ebx
	and	eax,7
	lea	rax,[rax+rax*2]
	lea	rax,[palette+rax*4]
	invoke	glUniform3f,[uColorLoc],float dword [rax],float dword [rax+4],float dword [rax+8]
	invoke	glDrawArrays,GL_TRIANGLES,0,36
	inc	ebx
	cmp	ebx,[bodyCount]
	jb	.body

	invoke	SwapBuffers,[hdc]
	xor	eax,eax
	jmp	finish
  wmkeydown:
	cmp	r8d,VK_ESCAPE
	je	wmdestroy
	cmp	r8d,VK_SPACE
	je	explode
	cmp	r8d,'R'
	jne	defwndproc
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

endp

; (re)create the world: a big static ground box and a pyramid of unit cubes
proc build_world uses rbx rsi rdi

	cmp	word [world],0
	je	.fresh
	invoke	b3DestroyWorld,[world]
  .fresh:
	mov	dword [bodyCount],0

	invoke	b3DefaultWorldDef,addr wdef	; returned via hidden pointer
	invoke	b3CreateWorld,addr wdef
	mov	[world],eax

	invoke	b3MakeBoxHull,addr cubeHull,float dword [cHalf],float dword [cHalf],float dword [cHalf]
	invoke	b3MakeBoxHull,addr groundHull,float dword [cGroundHX],float dword [cHalf],float dword [cGroundHX]

	invoke	b3DefaultShapeDef,addr sdef

	; static ground, top surface at y = 0
	invoke	b3DefaultBodyDef,addr bdef
	mov	eax,[cMinusHalf]
	mov	[bdef.position.y],eax
	invoke	b3CreateBody,[world],addr bdef
	invoke	b3CreateHullShape,rax,addr sdef,addr groundHull

	; pyramid of dynamic cubes
	mov	dword [bdef.type],b3_dynamicBody
	xor	ebx,ebx 			; rbx = level
  .level:
	mov	eax,PYRAMID_LEVELS
	sub	eax,ebx 			; n = boxes per side
	mov	[nSide],eax
	dec	eax
	cvtsi2ss xmm0,eax			; halfSpan = (n-1)*spacing/2
	mulss	xmm0,[cHalfSpacing]
	movss	[halfSpan],xmm0
	cvtsi2ss xmm0,ebx			; y = base + level*spacing
	mulss	xmm0,[cSpacing]
	addss	xmm0,[cBaseY]
	movss	[bdef.position.y],xmm0
	xor	esi,esi 			; rsi = x index
  .ix:
	xor	edi,edi 			; rdi = z index
  .iz:
	cvtsi2ss xmm0,esi
	mulss	xmm0,[cSpacing]
	subss	xmm0,[halfSpan]
	movss	[bdef.position.x],xmm0
	cvtsi2ss xmm0,edi
	mulss	xmm0,[cSpacing]
	subss	xmm0,[halfSpan]
	movss	[bdef.position.z],xmm0
	invoke	b3CreateBody,[world],addr bdef
	mov	ecx,[bodyCount]
	mov	[bodies+rcx*8],rax
	inc	dword [bodyCount]
	invoke	b3CreateHullShape,rax,addr sdef,addr cubeHull
	inc	edi
	cmp	edi,[nSide]
	jb	.iz
	inc	esi
	cmp	esi,[nSide]
	jb	.ix
	inc	ebx
	cmp	ebx,PYRAMID_LEVELS
	jb	.level

	ret

endp

section '.rdata' data readable

  _title db 'Box3D + fasm2 -- SPACE: explode, R: reset, ESC: quit',0
  _class db 'BOX3DFASM2',0

  _function_not_supported db 'Function not supported.',0
  _context_not_created db 'Failed to create OpenGL context.',0

  _wglCreateContextAttribsARB db 'wglCreateContextAttribsARB',0

  irpv name, CONTEXT_AWARE_FUNCTION
	_#name db `name,0
  end irpv

  vs_src file 'pyramid_vs.glsl'
	 db 0

  fs_src file 'pyramid_fs.glsl'
	 db 0

  uPos db 'uPos',0
  uQuat db 'uQuat',0
  uHalf db 'uHalf',0
  uColor db 'uColor',0
  uAspect db 'uAspect',0

  timeStep	dd 1.0/60.0
  cHalf 	dd 0.5
  cMinusHalf	dd -0.5
  cGroundHX	dd 18.0
  cSpacing	dd 1.40 	; box pitch, slightly above the 1m box size
  cHalfSpacing	dd 0.70
  cBaseY	dd 0.55 	; first layer floats just above the ground
  ; default shape density is 1000 kg/m^3, so each cube weighs a tonne;
  ; the impulse has to be sized accordingly
  cExpHeight	dd 0.5
  cExpRadius	dd 6.0
  cExpFalloff	dd 3.0
  cExpImpulse	dd 9000.0

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
	 PostQuitMessage,'PostQuitMessage'

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
