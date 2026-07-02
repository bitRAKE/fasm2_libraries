; Box3D fasm2 example: artistic stair dismount.
;
;   fasm2 dismount.asm
;
; Run with box3d.dll (build-shared\bin\Release) next to the executable.
; A jointed ragdoll stands at the top of a staircase. Aim a launch impulse
; and get judged on style, not damage:
;   flips   end-over-end rotation (about the lateral axis)
;   rolls   barrel rolls (about the travel axis)
;   twists  spins about the vertical axis
;   steps   distinct stairs contacted on the way down
;   wall    touches of the flanking walls
;   air     total airborne time
; This is a console application: aiming feedback, judges' notes during
; the run (each new step, the first wall contact), and the final tally
; breakdown all print to the console, high-dive scorecard style. The
; verdict lands when the ragdoll falls asleep or holds still.
;
; Controls:
;   Z/C    launch angle          A/D      launch power
;   Q/E    launch spin           SPACE    launch
;   W/S    launch side
;   R      reset                 ESC      quit
;
; The ragdoll is ten bodies: capsules for limbs and torso, a sphere for
; the head, tied together with spherical joints (neck, shoulders, hips;
; cone and twist limits) and revolute joints (elbows, knees; angle
; limits). Rotation is judged by integrating the torso angular velocity;
; step and wall contact come from contact begin events, with each static
; shape tagged through its userData; air time counts frames with no
; ragdoll-versus-static contact.
;
; Window and OpenGL setup follow fasm2's examples/opengl/opengl.asm; the
; renderer is the simple uniform-per-draw path from pyramid.asm.

format PE64 NX console 5.0
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

STATE_AIM		:= 0
STATE_FLIGHT		:= 1
STATE_REST		:= 2

STEP_COUNT		:= 14
RAGDOLL_PARTS		:= 10
JOINT_COUNT		:= 9

; static shape userData tags for scoring
TAG_STEP1		:= 1		; steps use 1..STEP_COUNT
TAG_GROUND		:= 20
TAG_PLATFORM		:= 21
TAG_WALL		:= 30

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
  sjd b3SphericalJointDef
  rjd b3RevoluteJointDef
  cevents b3ContactEvents
  cap b3Capsule
  sph b3Sphere
  tmpHull b3BoxHull
  wt b3WorldTransform
  wvel b3Vec3
  lvel b3Vec3
  impVec b3Vec3
  launchPoint b3Vec3

  ragdollIds rq RAGDOLL_PARTS
  world dd ?			; b3WorldId; null while index1 (low word) is zero

  ; game state
  state dd STATE_AIM
  aimAngle dd 40		; degrees above horizontal
  aimPower dd 6			; 1..10
  aimSpin dd 2			; -5..5, forward flips are positive
  aimSide dd 0			; -5..5, negative banks toward the wall

  ; judging accumulators
  flipDeg dd ?
  rollDeg dd ?
  twistDeg dd ?
  stepMask dd ?
  wallHits dd ?
  airFrames dd ?
  groundedCnt dd ?
  flightFrames dd ?
  stillFrames dd ?

  ; report scratch
  tmpPts dd ?
  totalPts dd ?

  ; static scenery draw list: pos vec3, half vec3, color vec3
  staticDraw rd (STEP_COUNT+3)*9
  staticCount dd ?
  tmpStatic rd 6		; scratch box descriptor: pos xyz, half xyz
  skipDraw dd ?			; add_static: create the collider but do not draw it

section '.text' code readable executable

  start:
	sub	rsp,8
	invoke	GetModuleHandle,0
	mov	[wc.hInstance],rax
	invoke	LoadIcon,0,IDI_APPLICATION
	mov	[wc.hIcon],rax
	invoke	LoadCursor,0,IDC_ARROW
	mov	[wc.hCursor],rax
	invoke	printf,_banner
	invoke	RegisterClass,wc
	invoke	CreateWindowEx,0,_class,_title,WS_VISIBLE+WS_OVERLAPPEDWINDOW+WS_CLIPCHILDREN+WS_CLIPSIBLINGS,64,64,1120,700,NULL,NULL,[wc.hInstance],NULL

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

	invoke	glVertexAttribPointer,0,3,GL_FLOAT,0,24,0	; position
	invoke	glEnableVertexAttribArray,0
	invoke	glVertexAttribPointer,1,3,GL_FLOAT,0,24,12	; normal
	invoke	glEnableVertexAttribArray,1

	invoke	glEnable,GL_DEPTH_TEST

	call	build_world
	call	print_aim

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

	cmp	dword [state],STATE_FLIGHT
	jne	.render

	invoke	b3World_Step,[world],float dword [timeStep],4
	inc	dword [flightFrames]

	; integrate the torso angular velocity into style degrees:
	; stairs descend along +x, so |w.z| is end-over-end, |w.x| is
	; barrel roll, |w.y| is twist
	invoke	b3Body_GetAngularVelocity,addr wvel,qword [ragdollIds]
	mov	eax,[wvel.z]
	and	eax,0x7FFFFFFF
	movd	xmm0,eax
	mulss	xmm0,[cDtDeg]
	addss	xmm0,[flipDeg]
	movss	[flipDeg],xmm0
	mov	eax,[wvel.x]
	and	eax,0x7FFFFFFF
	movd	xmm0,eax
	mulss	xmm0,[cDtDeg]
	addss	xmm0,[rollDeg]
	movss	[rollDeg],xmm0
	mov	eax,[wvel.y]
	and	eax,0x7FFFFFFF
	movd	xmm0,eax
	mulss	xmm0,[cDtDeg]
	addss	xmm0,[twistDeg]
	movss	[twistDeg],xmm0

	; contact events: steps and walls from begin events, air time from a
	; running count of ragdoll-versus-static touching contacts
	invoke	b3World_GetContactEvents,addr cevents,[world]
	mov	rsi,[cevents.beginEvents]
	mov	ebx,[cevents.beginCount]
	test	ebx,ebx
	jz	.ends
  .begin_event:
	invoke	b3Shape_GetUserData,qword [rsi+b3ContactBeginTouchEvent.shapeIdA]
	call	score_tag
	invoke	b3Shape_GetUserData,qword [rsi+b3ContactBeginTouchEvent.shapeIdB]
	call	score_tag
	add	rsi,sizeof.b3ContactBeginTouchEvent
	dec	ebx
	jnz	.begin_event
  .ends:
	mov	rsi,[cevents.endEvents]
	mov	ebx,[cevents.endCount]
	test	ebx,ebx
	jz	.air
  .end_event:
	invoke	b3Shape_GetUserData,qword [rsi+b3ContactEndTouchEvent.shapeIdA]
	call	unscore_tag
	invoke	b3Shape_GetUserData,qword [rsi+b3ContactEndTouchEvent.shapeIdB]
	call	unscore_tag
	add	rsi,sizeof.b3ContactEndTouchEvent
	dec	ebx
	jnz	.end_event
  .air:
	cmp	dword [groundedCnt],0
	jnz	.grounded
	inc	dword [airFrames]
  .grounded:

	; the verdict is in when the ragdoll falls asleep, or as a fallback
	; when the torso has been still for three seconds (a limb resting
	; against a joint limit can twitch forever and hold off sleep)
	cmp	dword [flightFrames],120
	jb	.hud
	invoke	b3Body_IsAwake,qword [ragdollIds]
	test	al,al
	jz	.rest
	invoke	b3Body_GetLinearVelocity,addr lvel,qword [ragdollIds]
	movss	xmm0,[lvel.x]
	mulss	xmm0,xmm0
	movss	xmm1,[lvel.y]
	mulss	xmm1,xmm1
	addss	xmm0,xmm1
	movss	xmm1,[lvel.z]
	mulss	xmm1,xmm1
	addss	xmm0,xmm1
	movss	xmm1,[wvel.x]
	mulss	xmm1,xmm1
	addss	xmm0,xmm1
	movss	xmm1,[wvel.y]
	mulss	xmm1,xmm1
	addss	xmm0,xmm1
	movss	xmm1,[wvel.z]
	mulss	xmm1,xmm1
	addss	xmm0,xmm1
	comiss	xmm0,[cStillThresh]
	jb	.still
	mov	dword [stillFrames],0
	jmp	.hud
  .still:
	inc	dword [stillFrames]
	cmp	dword [stillFrames],180
	jb	.hud
  .rest:
	mov	dword [state],STATE_REST
	call	print_report
  .hud:

  .render:
	invoke	glClearColor,float dword 0.07,float dword 0.08,float dword 0.11,float dword 1.0
	invoke	glClear,GL_COLOR_BUFFER_BIT+GL_DEPTH_BUFFER_BIT

	; scenery, identity rotation
	invoke	glUniform4f,[uQuatLoc],float dword 0.0,float dword 0.0,float dword 0.0,float dword 1.0
	xor	ebx,ebx
  .static:
	lea	rsi,[staticDraw+rbx]
	invoke	glUniform3f,[uPosLoc],float dword [rsi],float dword [rsi+4],float dword [rsi+8]
	invoke	glUniform3f,[uHalfLoc],float dword [rsi+12],float dword [rsi+16],float dword [rsi+20]
	invoke	glUniform3f,[uColorLoc],float dword [rsi+24],float dword [rsi+28],float dword [rsi+32]
	invoke	glDrawArrays,GL_TRIANGLES,0,36
	add	ebx,36
	mov	eax,[staticCount]
	imul	eax,36
	cmp	ebx,eax
	jb	.static

	; ragdoll parts at their body transforms
	xor	ebx,ebx
  .part:
	invoke	b3Body_GetTransform,addr wt,qword [ragdollIds+rbx*8]
	invoke	glUniform3f,[uPosLoc],float dword [wt.p.x],float dword [wt.p.y],float dword [wt.p.z]
	invoke	glUniform4f,[uQuatLoc],float dword [wt.q.v.x],float dword [wt.q.v.y],float dword [wt.q.v.z],float dword [wt.q.s]
	imul	esi,ebx,48
	lea	rsi,[parts+rsi]
	invoke	glUniform3f,[uHalfLoc],float dword [rsi+20],float dword [rsi+24],float dword [rsi+28]
	invoke	glUniform3f,[uColorLoc],float dword [rsi+32],float dword [rsi+36],float dword [rsi+40]
	invoke	glDrawArrays,GL_TRIANGLES,0,36
	inc	ebx
	cmp	ebx,RAGDOLL_PARTS
	jb	.part

	invoke	SwapBuffers,[hdc]
	xor	eax,eax
	jmp	finish
  wmkeydown:
	cmp	r8d,VK_ESCAPE
	je	wmdestroy
	cmp	r8d,'R'
	je	.reset
	cmp	dword [state],STATE_AIM
	jne	defwndproc
	cmp	r8d,VK_SPACE
	je	.launch
	cmp	r8d,'X'
	je	.launch
	cmp	r8d,'Z'
	je	.angle_up
	cmp	r8d,'C'
	je	.angle_down
	cmp	r8d,'D'
	je	.power_up
	cmp	r8d,'A'
	je	.power_down
	cmp	r8d,'Q'
	je	.spin_down
	cmp	r8d,'E'
	je	.spin_up
	cmp	r8d,'W'
	je	.side_down
	cmp	r8d,'S'
	je	.side_up
	jmp	defwndproc
  .reset:
	call	build_world
	invoke	printf,_newRun
	jmp	.aim_hud
  .angle_up:
	cmp	dword [aimAngle],80
	jae	.aim_hud
	add	dword [aimAngle],5
	jmp	.aim_hud
  .angle_down:
	cmp	dword [aimAngle],0
	jle	.aim_hud
	sub	dword [aimAngle],5
	jmp	.aim_hud
  .power_up:
	cmp	dword [aimPower],10
	jae	.aim_hud
	inc	dword [aimPower]
	jmp	.aim_hud
  .power_down:
	cmp	dword [aimPower],1
	jbe	.aim_hud
	dec	dword [aimPower]
	jmp	.aim_hud
  .spin_up:
	cmp	dword [aimSpin],5
	jge	.aim_hud
	inc	dword [aimSpin]
	jmp	.aim_hud
  .spin_down:
	cmp	dword [aimSpin],-5
	jle	.aim_hud
	dec	dword [aimSpin]
	jmp	.aim_hud
  .side_up:
	cmp	dword [aimSide],5
	jge	.aim_hud
	inc	dword [aimSide]
	jmp	.aim_hud
  .side_down:
	cmp	dword [aimSide],-5
	jle	.aim_hud
	dec	dword [aimSide]
  .aim_hud:
	call	print_aim
	xor	eax,eax
	jmp	finish
  .launch:
	; impulse = power * scale * (cos a, sin a, 0) at the torso center
	cvtsi2ss xmm1,[aimAngle]
	mulss	xmm1,[cDegRad]
	invoke	b3ComputeCosSin,float xmm1	; 8-byte struct returns in rax
	cvtsi2ss xmm2,[aimPower]
	mulss	xmm2,[cImpScale]
	movd	xmm0,eax
	mulss	xmm0,xmm2
	movss	[impVec.x],xmm0
	shr	rax,32
	movd	xmm0,eax
	mulss	xmm0,xmm2
	movss	[impVec.y],xmm0
	cvtsi2ss xmm0,[aimSide]
	mulss	xmm0,[cSideScale]
	movss	[impVec.z],xmm0
	invoke	b3Body_ApplyLinearImpulse,qword [ragdollIds],addr impVec,addr launchPoint,1
	; forward flips rotate about -z when travelling +x
	cvtsi2ss xmm0,[aimSpin]
	mulss	xmm0,[cSpinScale]
	xorps	xmm1,xmm1
	subss	xmm1,xmm0
	movss	[impVec.z],xmm1
	xor	eax,eax
	mov	[impVec.x],eax
	mov	[impVec.y],eax
	invoke	b3Body_ApplyAngularImpulse,qword [ragdollIds],addr impVec,1
	mov	dword [state],STATE_FLIGHT
	invoke	printf,_launch,[aimAngle],[aimPower],[aimSpin],[aimSide]
	invoke	fflush,0
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

; rax = shape userData tag from a contact begin event
proc score_tag
	test	rax,rax
	jz	.done			; ragdoll part
	cmp	eax,TAG_STEP1+STEP_COUNT-1
	ja	.not_step
	lea	ecx,[eax-TAG_STEP1]
	bts	[stepMask],ecx
	jc	.static 		; already visited this step
	invoke	printf,_noteStep,eax	; a judge takes note
	invoke	fflush,0
	jmp	.static
  .not_step:
	cmp	eax,TAG_WALL
	jne	.static
	inc	dword [wallHits]
	cmp	dword [wallHits],1
	jne	.static
	invoke	printf,_noteWall
	invoke	fflush,0
  .static:
	inc	dword [groundedCnt]
  .done:
	ret
endp

; rax = shape userData tag from a contact end event
proc unscore_tag
	test	rax,rax
	jz	.done
	dec	dword [groundedCnt]
  .done:
	ret
endp

; print the aim line, overwriting itself with a carriage return
proc print_aim
	invoke	printf,_aimLine,[aimAngle],[aimPower],[aimSpin],[aimSide]
	invoke	fflush,0	; keep redirected output live as well
	ret
endp

; one category line of the judges' report:
; xmm0 = quantity as single float, ecx = integer points; both printed
proc report_line uses rbx
	mov	rbx,rdx 		; format string
	add	[totalPts],ecx
	mov	[tmpPts],ecx
	cvtss2sd xmm0,xmm0
	movq	rax,xmm0
	invoke	printf,rbx,rax,[tmpPts]
	ret
endp

; the judges tally the details of the completed run
proc print_report
	mov	dword [totalPts],0

	invoke	printf,_repHead,[aimAngle],[aimPower],[aimSpin],[aimSide]

	movss	xmm0,[flipDeg]
	mulss	xmm0,[cFlipPts]
	cvtss2si ecx,xmm0
	movss	xmm0,[flipDeg]
	mulss	xmm0,[cInv360]
	mov	rdx,_repFlips
	call	report_line

	movss	xmm0,[rollDeg]
	mulss	xmm0,[cRollPts]
	cvtss2si ecx,xmm0
	movss	xmm0,[rollDeg]
	mulss	xmm0,[cInv360]
	mov	rdx,_repRolls
	call	report_line

	movss	xmm0,[twistDeg]
	mulss	xmm0,[cTwistPts]
	cvtss2si ecx,xmm0
	movss	xmm0,[twistDeg]
	mulss	xmm0,[cInv360]
	mov	rdx,_repTwists
	call	report_line

	popcnt	eax,[stepMask]
	imul	ecx,eax,100
	add	[totalPts],ecx
	mov	[tmpPts],ecx
	invoke	printf,_repSteps,eax,[tmpPts]

	mov	eax,[wallHits]
	cmp	eax,8
	jbe	@f
	mov	eax,8			; the judges cap wall points
    @@:
	imul	ecx,eax,150
	add	[totalPts],ecx
	mov	[tmpPts],ecx
	invoke	printf,_repWall,[wallHits],[tmpPts]

	mov	eax,[airFrames]
	lea	ecx,[eax+eax]		; 2 points per airborne frame = 120/s
	cvtsi2ss xmm0,eax
	mulss	xmm0,[timeStep]
	mov	rdx,_repAir
	call	report_line

	invoke	printf,_repTotal,[totalPts]
	invoke	fflush,0
	ret
endp

; place one static box body: position/half from tmpStatic, tag in eax;
; also appends the draw-list entry with the color at [rdi]
proc add_static uses rbx rdi
	mov	[sdef.userData],rax
	invoke	b3MakeBoxHull,addr tmpHull,float dword [tmpStatic+12],float dword [tmpStatic+16],float dword [tmpStatic+20]
	invoke	b3DefaultBodyDef,addr bdef
	mov	eax,[tmpStatic]
	mov	[bdef.position.x],eax
	mov	eax,[tmpStatic+4]
	mov	[bdef.position.y],eax
	mov	eax,[tmpStatic+8]
	mov	[bdef.position.z],eax
	invoke	b3CreateBody,[world],addr bdef
	invoke	b3CreateHullShape,rax,addr sdef,addr tmpHull
	cmp	dword [skipDraw],0
	jnz	.done
	mov	eax,[staticCount]
	imul	eax,36
	lea	rbx,[staticDraw+rax]
	mov	rax,qword [tmpStatic]		; pos + half, 24 bytes
	mov	qword [rbx],rax
	mov	rax,qword [tmpStatic+8]
	mov	qword [rbx+8],rax
	mov	rax,qword [tmpStatic+16]
	mov	qword [rbx+16],rax
	mov	rax,qword [rdi]			; color, 12 bytes
	mov	qword [rbx+24],rax
	mov	eax,[rdi+8]
	mov	[rbx+32],eax
	inc	dword [staticCount]
  .done:
	ret
endp

; (re)create the world: staircase scenery and the jointed ragdoll
proc build_world uses rbx rsi rdi

	cmp	word [world],0
	je	.fresh
	invoke	b3DestroyWorld,[world]
  .fresh:
	; reset the run
	mov	dword [state],STATE_AIM
	xor	eax,eax
	mov	[flipDeg],eax
	mov	[rollDeg],eax
	mov	[twistDeg],eax
	mov	[stepMask],eax
	mov	[wallHits],eax
	mov	[airFrames],eax
	mov	[groundedCnt],eax
	mov	[flightFrames],eax
	mov	[stillFrames],eax
	mov	[staticCount],eax

	invoke	b3DefaultWorldDef,addr wdef	; returned via hidden pointer
	mov	dword [wdef.workerCount],4
	invoke	b3CreateWorld,addr wdef
	mov	[world],eax

	; scenery shapes get contact events so the judges can see them
	invoke	b3DefaultShapeDef,addr sdef
	mov	byte [sdef.enableContactEvents],1

	; ground (copy_static clobbers rax, so the tag loads afterward)
	lea	rdi,[cGroundCol]
	lea	rsi,[cGroundBox]
	call	copy_static
	mov	eax,TAG_GROUND
	call	add_static

	; launch platform
	lea	rdi,[cPlatformCol]
	lea	rsi,[cPlatformBox]
	call	copy_static
	mov	eax,TAG_PLATFORM
	call	add_static

	; far wall, drawn as the backdrop
	lea	rdi,[cWallCol]
	lea	rsi,[cWallBox]
	call	copy_static
	mov	eax,TAG_WALL
	call	add_static

	; near wall: same collider on the camera side, invisible
	mov	dword [skipDraw],1
	lea	rdi,[cWallCol]
	lea	rsi,[cWallBoxNear]
	call	copy_static
	mov	eax,TAG_WALL
	call	add_static
	mov	dword [skipDraw],0

	; staircase: step i tops out at 5.6 - 0.4*(i+1), built as a column
	xor	ebx,ebx
  .step:
	cvtsi2ss xmm0,ebx
	mulss	xmm0,[cStepRun]
	addss	xmm0,[cStepX0]
	movss	[tmpStatic],xmm0		; center x
	lea	eax,[ebx+1]
	cvtsi2ss xmm0,eax
	mulss	xmm0,[cStepRise]
	movss	xmm1,[cStairTop]
	subss	xmm1,xmm0			; top of this step
	mulss	xmm1,[cHalfF]
	movss	[tmpStatic+4],xmm1		; center y = half height
	movss	[tmpStatic+16],xmm1		; half y
	xor	eax,eax
	mov	[tmpStatic+8],eax		; z
	mov	eax,[cStepHalfX]
	mov	[tmpStatic+12],eax
	mov	eax,[cStepHalfZ]
	mov	[tmpStatic+20],eax
	lea	rdi,[cStepColA]
	test	ebx,1
	jz	@f
	lea	rdi,[cStepColB]
    @@:
	lea	eax,[ebx+TAG_STEP1]
	call	add_static
	inc	ebx
	cmp	ebx,STEP_COUNT
	jb	.step

	; ragdoll parts: capsules and a sphere head, contact events enabled,
	; a little bounce for style
	invoke	b3DefaultShapeDef,addr sdef
	mov	byte [sdef.enableContactEvents],1
	mov	eax,[cRestitution]
	mov	[sdef.baseMaterial.restitution],eax
	xor	eax,eax
	mov	[sdef.userData],rax

	invoke	b3DefaultBodyDef,addr bdef
	mov	dword [bdef.type],b3_dynamicBody

	xor	ebx,ebx
  .part:
	imul	esi,ebx,48
	lea	rsi,[parts+rsi]
	movss	xmm0,[rsi]
	addss	xmm0,[cSpawnX]
	movss	[bdef.position.x],xmm0
	movss	xmm0,[rsi+4]
	addss	xmm0,[cSpawnY]
	movss	[bdef.position.y],xmm0
	mov	eax,[rsi+8]
	mov	[bdef.position.z],eax
	invoke	b3CreateBody,[world],addr bdef
	mov	[ragdollIds+rbx*8],rax
	cmp	dword [rsi+44],1
	je	.sphere
	xor	eax,eax
	mov	[cap.center1.x],eax
	mov	[cap.center1.z],eax
	mov	[cap.center2.x],eax
	mov	[cap.center2.z],eax
	mov	eax,[rsi+16]
	mov	[cap.center2.y],eax
	btc	eax,31				; negate the float
	mov	[cap.center1.y],eax
	mov	eax,[rsi+12]
	mov	[cap.radius],eax
	invoke	b3CreateCapsuleShape,qword [ragdollIds+rbx*8],addr sdef,addr cap
	jmp	.next_part
  .sphere:
	xor	eax,eax
	mov	[sph.center.x],eax
	mov	[sph.center.y],eax
	mov	[sph.center.z],eax
	mov	eax,[rsi+12]
	mov	[sph.radius],eax
	invoke	b3CreateSphereShape,qword [ragdollIds+rbx*8],addr sdef,addr sph
  .next_part:
	inc	ebx
	cmp	ebx,RAGDOLL_PARTS
	jb	.part

	; joints: local frames are anchor minus body center, identity rotation
	xor	ebx,ebx
  .joint:
	imul	esi,ebx,24
	lea	rsi,[joints+rsi]
	cmp	dword [rsi],1
	je	.revolute

	invoke	b3DefaultSphericalJointDef,addr sjd
	mov	eax,[rsi+4]
	mov	rax,[ragdollIds+rax*8]
	mov	[sjd.base.bodyIdA],rax
	mov	eax,[rsi+8]
	mov	rax,[ragdollIds+rax*8]
	mov	[sjd.base.bodyIdB],rax
	lea	rdi,[sjd.base.localFrameA.p]
	mov	eax,[rsi+4]
	call	local_anchor
	lea	rdi,[sjd.base.localFrameB.p]
	mov	eax,[rsi+8]
	call	local_anchor
	mov	byte [sjd.enableConeLimit],1
	mov	eax,[cConeAngle]
	mov	[sjd.coneAngle],eax
	mov	byte [sjd.enableTwistLimit],1
	mov	eax,[cTwistLo]
	mov	[sjd.lowerTwistAngle],eax
	mov	eax,[cTwistHi]
	mov	[sjd.upperTwistAngle],eax
	invoke	b3CreateSphericalJoint,[world],addr sjd
	jmp	.next_joint

  .revolute:
	invoke	b3DefaultRevoluteJointDef,addr rjd
	mov	eax,[rsi+4]
	mov	rax,[ragdollIds+rax*8]
	mov	[rjd.base.bodyIdA],rax
	mov	eax,[rsi+8]
	mov	rax,[ragdollIds+rax*8]
	mov	[rjd.base.bodyIdB],rax
	lea	rdi,[rjd.base.localFrameA.p]
	mov	eax,[rsi+4]
	call	local_anchor
	lea	rdi,[rjd.base.localFrameB.p]
	mov	eax,[rsi+8]
	call	local_anchor
	mov	byte [rjd.enableLimit],1
	mov	eax,[cHingeLo]
	mov	[rjd.lowerAngle],eax
	mov	eax,[cHingeHi]
	mov	[rjd.upperAngle],eax
	invoke	b3CreateRevoluteJoint,[world],addr rjd

  .next_joint:
	inc	ebx
	cmp	ebx,JOINT_COUNT
	jb	.joint

	; the launch impulse is applied at the torso center
	movss	xmm0,[parts]
	addss	xmm0,[cSpawnX]
	movss	[launchPoint.x],xmm0
	movss	xmm0,[parts+4]
	addss	xmm0,[cSpawnY]
	movss	[launchPoint.y],xmm0
	xor	eax,eax
	mov	[launchPoint.z],eax

	ret

endp

; copy a 6-float box descriptor (pos, half) from [rsi] to tmpStatic
proc copy_static
	mov	rax,qword [rsi]
	mov	qword [tmpStatic],rax
	mov	rax,qword [rsi+8]
	mov	qword [tmpStatic+8],rax
	mov	rax,qword [rsi+16]
	mov	qword [tmpStatic+16],rax
	ret
endp

; eax = part index, rdi = destination b3Vec3; writes joint anchor [rsi+12]
; minus the part spawn position (both relative to the spawn base)
proc local_anchor
	imul	eax,eax,48
	lea	rcx,[parts+rax]
	movss	xmm0,[rsi+12]
	subss	xmm0,[rcx]
	movss	[rdi],xmm0
	movss	xmm0,[rsi+16]
	subss	xmm0,[rcx+4]
	movss	[rdi+4],xmm0
	movss	xmm0,[rsi+20]
	subss	xmm0,[rcx+8]
	movss	[rdi+8],xmm0
	ret
endp

section '.rdata' data readable

  _class db 'BOX3DDISMOUNT',0
  _title db 'Box3D fasm2 dismount',0

  _banner db 'Box3D fasm2 dismount -- artistic stair dismount',10
	  db 'aim with Z/C (angle), A/D (power), Q/E (spin), W/S (side)',10
	  db 'SPACE or X launches, R resets, ESC quits',10,10,0

  _aimLine db 13,'aim> angle=%-3d power=%-3d spin=%-3d side=%-3d ',0
  _launch db 10,10,'launch: angle=%d power=%d spin=%d side=%d',10,0
  _newRun db 10,'the ragdoll limps back up the stairs',10,10,0

  _noteStep db '  step %d',10,0
  _noteWall db '  wall contact',10,0

  _repHead db 10,'=============== JUDGES'' REPORT ===============',10
	   db '  launch        angle %d deg, power %d, spin %d, side %d',10,0
  _repFlips  db '  flips        %6.2f turns    x 500 = %6d',10,0
  _repRolls  db '  barrel rolls %6.2f turns    x 300 = %6d',10,0
  _repTwists db '  twists       %6.2f turns    x 200 = %6d',10,0
  _repSteps  db '  steps        %3d of 14      x 100 = %6d',10,0
  _repWall   db '  wall rides   %3d (cap 8)    x 150 = %6d',10,0
  _repAir    db '  air time     %6.2f s        x 120 = %6d',10,0
  _repTotal  db '  --------------------------------------------',10
	     db '  TOTAL                              %6d',10
	     db '==============================================',10
	     db 'press R for another run',10,0

  _function_not_supported db 'Function not supported.',0
  _context_not_created db 'Failed to create OpenGL context.',0

  _wglCreateContextAttribsARB db 'wglCreateContextAttribsARB',0

  irpv name, CONTEXT_AWARE_FUNCTION
	_#name db `name,0
  end irpv

  vs_src file 'dismount_vs.glsl'
	 db 0

  fs_src file 'dismount_fs.glsl'
	 db 0

  uPos db 'uPos',0
  uQuat db 'uQuat',0
  uHalf db 'uHalf',0
  uColor db 'uColor',0
  uAspect db 'uAspect',0

  timeStep	dd 1.0/60.0
  cHalfF	dd 0.5
  cSpawnX	dd -0.4
  cSpawnY	dd 5.6		; platform top
  cStairTop	dd 5.6
  cStepRise	dd 0.4
  cStepRun	dd 0.6
  cStepX0	dd 0.9		; center of the first step
  cStepHalfX	dd 0.3
  cStepHalfZ	dd 2.0
  cDegRad	dd 0.017453293
  cDtDeg	dd 0.95492966	; (1/60) * (180/pi)
  cInv360	dd 1.0/360.0
  cImpScale	dd 100.0	; launch impulse per power unit (N*s)
  cSpinScale	dd 25.0 	; angular impulse per spin unit (N*m*s)
  cSideScale	dd 20.0 	; sideways impulse per side unit (N*s)
  cRestitution	dd 0.2
  cConeAngle	dd 1.3
  cTwistLo	dd -0.6
  cTwistHi	dd 0.6
  cHingeLo	dd -2.0
  cHingeHi	dd 2.0
  cStillThresh	dd 0.02 	; |v|^2 + |w|^2 below this counts as still
  cFlipPts	dd 500.0/360.0
  cRollPts	dd 300.0/360.0
  cTwistPts	dd 200.0/360.0

  ; static boxes: pos xyz, half xyz
  cGroundBox	dd 8.0, -0.5, 0.0,   30.0, 0.5, 8.0
  cPlatformBox	dd -1.0, 2.8, 0.0,   1.6, 2.8, 2.0
  ; the walls hug the stairs on both sides so a tumbling ragdoll can brush
  ; them for points; the near one is not drawn so the camera sees through it
  cWallBox	dd 4.0, 10.0, -0.9,  9.0, 10.0, 0.2
  cWallBoxNear	dd 4.0, 10.0,  0.9,  9.0, 10.0, 0.2

  cGroundCol	dd 0.33, 0.35, 0.38
  cPlatformCol	dd 0.42, 0.44, 0.47
  cWallCol	dd 0.20, 0.22, 0.30
  cStepColA	dd 0.45, 0.47, 0.50
  cStepColB	dd 0.38, 0.40, 0.43

  ; ragdoll parts, positions relative to the spawn base (feet at 0):
  ; pos xyz, capsule radius, capsule half length, draw half xyz,
  ; color rgb, type (0 capsule, 1 sphere)
  parts:
	dd 0.0, 1.29,  0.0,	0.15, 0.25,  0.16, 0.40, 0.16,	0.86, 0.19, 0.20,  0	; torso
	dd 0.0, 1.76,  0.0,	0.12, 0.0,   0.12, 0.12, 0.12,	0.96, 0.80, 0.60,  1	; head
	dd 0.0, 1.38, -0.22,	0.06, 0.12,  0.07, 0.18, 0.07,	0.19, 0.68, 0.75,  0	; upper arm L
	dd 0.0, 1.38,  0.22,	0.06, 0.12,  0.07, 0.18, 0.07,	0.19, 0.68, 0.75,  0	; upper arm R
	dd 0.0, 1.03, -0.22,	0.05, 0.12,  0.06, 0.17, 0.06,	0.25, 0.78, 0.85,  0	; forearm L
	dd 0.0, 1.03,  0.22,	0.05, 0.12,  0.06, 0.17, 0.06,	0.25, 0.78, 0.85,  0	; forearm R
	dd 0.0, 0.70, -0.10,	0.08, 0.16,  0.09, 0.24, 0.09,	0.30, 0.30, 0.55,  0	; thigh L
	dd 0.0, 0.70,  0.10,	0.08, 0.16,  0.09, 0.24, 0.09,	0.30, 0.30, 0.55,  0	; thigh R
	dd 0.0, 0.23, -0.10,	0.07, 0.16,  0.08, 0.23, 0.08,	0.36, 0.36, 0.65,  0	; shin L
	dd 0.0, 0.23,  0.10,	0.07, 0.16,  0.08, 0.23, 0.08,	0.36, 0.36, 0.65,  0	; shin R

  ; joints: type (0 spherical, 1 revolute), part A, part B, anchor xyz
  joints:
	dd 0,  0, 1,	0.0, 1.64,  0.0 	; neck
	dd 0,  0, 2,	0.0, 1.56, -0.22	; shoulder L
	dd 0,  0, 3,	0.0, 1.56,  0.22	; shoulder R
	dd 1,  2, 4,	0.0, 1.20, -0.22	; elbow L
	dd 1,  3, 5,	0.0, 1.20,  0.22	; elbow R
	dd 0,  0, 6,	0.0, 0.94, -0.10	; hip L
	dd 0,  0, 7,	0.0, 0.94,  0.10	; hip R
	dd 1,  6, 8,	0.0, 0.46, -0.10	; knee L
	dd 1,  7, 9,	0.0, 0.46,  0.10	; knee R

  align 8

  data import

  library kernel,'KERNEL32.DLL',\
	  user,'USER32.DLL',\
	  gdi,'GDI32.DLL',\
	  opengl,'OPENGL32.DLL',\
	  msvcrt,'msvcrt.dll',\
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

  import msvcrt,\
	 printf,'printf',\
	 fflush,'fflush'

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
