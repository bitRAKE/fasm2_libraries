; ABI conformance twin of api_check.c, driven through the fasm2 bindings.
;
; Performs the identical deterministic Box3D call sequence and folds every
; result into b3Hash. Linked against the same box3d import library, the
; printed hashes must match api_check.exe (the C reference) bit for bit;
; a divergence pinpoints a calling-convention misunderstanding in the
; bindings. See api_check.c for the catalogue of covered shapes.
;
;   fasm2 api_check.asm
;   link api_check.obj box3d.lib libcmt.lib legacy_stdio_definitions.lib

format MS64 COFF

include 'box3d.inc'
include 'box3d.extrn.inc'
include 'macro/proc64.inc'

public main
extrn printf

; fold a result into the running hash
macro FOLD addr,count
	fastcall b3Hash,[gH],addr,count
	mov	[gH],eax
end macro

macro PHASE name
	fastcall printf,_phFmt,name,[gH]
end macro

section '.text' code readable executable

; float b3CastResultFcn(shapeId, point*, normal*, fraction, materialId,
;                       triangleIndex, childIndex, context)
proc CastCb
	movd	eax,xmm3		; fraction bits
	add	eax,ecx 		; + shapeId.index1 (low dword)
	add	[gAcc],eax
	inc	dword [gCount]
	movss	xmm0,[cOneF]		; return 1.0: continue
	ret
endp

; bool b3OverlapResultFcn(shapeId, context)
proc OverlapCb
	add	[gAcc],ecx		; shapeId.index1
	inc	dword [gCount]
	mov	al,1
	ret
endp

; bool b3TreeQueryCallbackFcn(proxyId, userData, context)
proc TreeQueryCb
	add	[gAcc],edx		; low dword of userData
	inc	dword [gCount]
	mov	al,1
	ret
endp

; float b3TreeRayCastCallbackFcn(input*, proxyId, userData, context)
proc TreeRayCb
	add	[gAcc],r8d		; low dword of userData
	inc	dword [gCount]
	movss	xmm0,[rcx+b3RayCastInput.maxFraction]	; continue unclipped
	ret
endp

proc main uses rbx rsi rdi

  ; ------------------------------------------------------------ math
	fastcall b3Atan2,float dword [c05],float dword [c15]
	movss	dword [res],xmm0
	FOLD	res,4

	fastcall b3ComputeCosSin,float dword [c075]	; 8-byte float pair in RAX
	mov	[res],rax
	FOLD	res,8

	fastcall b3ComputeQuatBetweenUnitVectors,res,vAxisX,vAxisY
	FOLD	res,16

	fastcall b3Steiner,res,float dword [c25],vOrigin ; float + by-ref, 36-byte return
	FOLD	res,36

	fastcall b3PointToSegmentDistance,res,vA,vB,vC
	FOLD	res,12

	; hidden pointer + four by-ref arguments: the last lands on the stack
	fastcall b3SegmentDistance,res,vP1,vQ1,vP2,vQ2
	FOLD	res,32

	fastcall b3IsValidVec3,v123	; bool returns live in AL
	mov	[res],al
	FOLD	res,1

	fastcall b3MakeQuatFromMatrix,res,matIdent
	FOLD	res,16

	PHASE	_math

  ; -------------------------------------------------------- geometry
	fastcall b3MakeBoxHull,boxB,float dword [c05],float dword [c075],float dword [c10]
	FOLD	boxB,sizeof.b3BoxHull

	; hidden pointer + 3 floats + by-ref transform: 5th slot on the stack
	fastcall b3MakeTransformedBoxHull,boxT,float dword [c05],float dword [c05],float dword [c05],tBox
	FOLD	boxT,sizeof.b3BoxHull

	fastcall b3ComputeHullMass,res,boxB,float dword [c20] ; ptr then float in slot 3
	FOLD	res,52

	fastcall b3ComputeSphereAABB,res,sphereS,tSph
	FOLD	res,24

	fastcall b3CreateCylinder,float dword [c20],float dword [c05],float dword [c025],8
	mov	rsi,rax 		; pointer return
	fastcall b3Hash,[gH],rsi,dword [rsi+b3HullData.byteCount]
	mov	[gH],eax
	fastcall b3DestroyHull,rsi

	fastcall b3RayCastSphere,res,sphereS,raySph
	FOLD	res,45		; through the hit bool; padding follows

	lea	rax,[ptA]
	mov	[din.proxyA.points],rax
	mov	dword [din.proxyA.count],1
	mov	eax,[c05]
	mov	[din.proxyA.radius],eax
	lea	rax,[ptB]
	mov	[din.proxyB.points],rax
	mov	dword [din.proxyB.count],1
	mov	eax,[c025]
	mov	[din.proxyB.radius],eax
	mov	eax,[c10]
	mov	[din.transform.q.s],eax
	mov	byte [din.useRadii],1
	fastcall b3ShapeDistance,res,din,cacheS,0,0
	FOLD	res,48
	FOLD	cacheS,14	; metric, count, indices; padding follows

	PHASE	_geom

  ; ----------------------------------------------------------- world
	fastcall b3DefaultWorldDef,wdef
	mov	dword [wdef.workerCount],1
	FOLD	wdef,36 	; gravity through maximumLinearSpeed

	fastcall b3CreateWorld,wdef	; 4-byte struct returned in EAX
	mov	[worldId],eax
	FOLD	worldId,4

	fastcall b3World_IsValid,[worldId]
	mov	[res],al
	FOLD	res,1

	fastcall b3DefaultBodyDef,bdef
	FOLD	bdef,sizeof.b3BodyDef	; b3BodyDef has no padding
	fastcall b3DefaultShapeDef,sdef
	FOLD	sdef.density,8		; density + explosionScale
	FOLD	sdef.enableCustomFiltering,8	; the eight bools

	mov	eax,[cM05]
	mov	[bdef.position.y],eax
	fastcall b3CreateBody,[worldId],bdef	; 8-byte struct in RAX
	mov	[groundId],rax
	FOLD	groundId,8
	fastcall b3MakeBoxHull,boxG,float dword [c100],float dword [c05],float dword [c100]
	fastcall b3CreateHullShape,[groundId],sdef,boxG
	mov	[res],rax
	FOLD	res,8

	mov	dword [bdef.type],b3_dynamicBody
	xor	eax,eax
	mov	[bdef.position.x],eax
	mov	[bdef.position.z],eax
	mov	eax,[c30]
	mov	[bdef.position.y],eax
	fastcall b3CreateBody,[worldId],bdef
	mov	[bodyIds],rax
	FOLD	bodyIds,8
	fastcall b3CreateSphereShape,[bodyIds],sdef,shSphere
	mov	[shapeSphereId],rax
	FOLD	shapeSphereId,8

	mov	eax,[c025]
	mov	[bdef.position.x],eax
	mov	[bdef.position.z],eax
	mov	eax,[c50]
	mov	[bdef.position.y],eax
	fastcall b3CreateBody,[worldId],bdef
	mov	[bodyIds+8],rax
	fastcall b3CreateCapsuleShape,[bodyIds+8],sdef,shCapsule
	mov	[res],rax
	FOLD	res,8

	mov	eax,[cM05]
	mov	[bdef.position.x],eax
	xor	eax,eax
	mov	[bdef.position.z],eax
	mov	eax,[c70]
	mov	[bdef.position.y],eax
	fastcall b3CreateBody,[worldId],bdef
	mov	[bodyIds+16],rax
	fastcall b3MakeBoxHull,boxC,float dword [c05],float dword [c05],float dword [c05]
	fastcall b3CreateHullShape,[bodyIds+16],sdef,boxC
	mov	[res],rax
	FOLD	res,8

	mov	edi,90
  .step1:
	fastcall b3World_Step,[worldId],float dword [cDt],4	; 1/64, exact
	dec	edi
	jnz	.step1

	xor	ebx,ebx
  .bodyfold:
	fastcall b3Body_GetTransform,res,qword [bodyIds+rbx*8]
	FOLD	res,28
	fastcall b3Body_GetLinearVelocity,res,qword [bodyIds+rbx*8]
	FOLD	res,12
	fastcall b3Body_GetAngularVelocity,res,qword [bodyIds+rbx*8]
	FOLD	res,12
	fastcall b3Body_GetMass,qword [bodyIds+rbx*8]
	movss	dword [res],xmm0
	FOLD	res,4
	fastcall b3Body_GetMassData,res,qword [bodyIds+rbx*8]
	FOLD	res,52
	fastcall b3Body_GetLocalRotationalInertia,res,qword [bodyIds+rbx*8]
	FOLD	res,36
	fastcall b3Body_IsAwake,qword [bodyIds+rbx*8]
	mov	[res],al
	FOLD	res,1
	inc	ebx
	cmp	ebx,3
	jb	.bodyfold

	fastcall b3Body_SetGravityScale,[bodyIds],float dword [c05]
	fastcall b3Body_GetGravityScale,[bodyIds]
	movss	dword [res],xmm0
	FOLD	res,4

	fastcall b3Body_ApplyForce,[bodyIds],vForce,pAt,1
	mov	edi,30
  .step2:
	fastcall b3World_Step,[worldId],float dword [cDt],4
	dec	edi
	jnz	.step2
	fastcall b3Body_GetTransform,res,[bodyIds]
	FOLD	res,28

	fastcall b3Shape_SetFriction,[shapeSphereId],float dword [c075]
	fastcall b3Shape_GetFriction,[shapeSphereId]
	movss	dword [res],xmm0
	FOLD	res,4
	fastcall b3Shape_GetFilter,res,[shapeSphereId]	; 24 bytes via hidden pointer
	FOLD	res,20		; through groupIndex; padding follows
	fastcall b3Shape_EnableContactEvents,[shapeSphereId],1
	fastcall b3Shape_AreContactEventsEnabled,[shapeSphereId]
	mov	[res],al
	FOLD	res,1

	fastcall b3World_GetCounters,counters,[worldId]	; 200 bytes via hidden pointer
	FOLD	counters,20				; first five counters only

	fastcall b3World_GetAwakeBodyCount,[worldId]
	mov	[res],eax
	FOLD	res,4
	fastcall b3World_GetGravity,res,[worldId]
	FOLD	res,12

	; id + by-ref + xmm2 + xmm3 + stack float + stack bool
	fastcall b3Shape_ApplyWind,[shapeSphereId],vWind,float dword [c05],float dword [c025],float dword [c80],1
	mov	edi,10
  .step3:
	fastcall b3World_Step,[worldId],float dword [cDt],4
	dec	edi
	jnz	.step3
	fastcall b3Body_GetTransform,res,[bodyIds]
	FOLD	res,28

	PHASE	_world

  ; ----------------------------------------------------------- query
	fastcall b3DefaultQueryFilter,qfS
	FOLD	qfS,32

	; hidden pointer + world + two by-ref + by-ref filter: stack spill
	fastcall b3World_CastRayClosest,res,[worldId],pOrigin,vTrans,qfS
	FOLD	res,61		; through the hit bool; padding follows

	xor	eax,eax
	mov	[gAcc],eax
	mov	[gCount],eax
	fastcall b3World_CastRay,[worldId],pOrigin,vTrans,qfS,CastCb,0
	mov	[res],rax		; 8-byte struct returned in RAX
	FOLD	res,8
	FOLD	gAcc,4
	FOLD	gCount,4

	xor	eax,eax
	mov	[gAcc],eax
	mov	[gCount],eax
	fastcall b3World_OverlapAABB,[worldId],aabbBig,qfS,OverlapCb,0
	mov	[res],rax
	FOLD	res,8
	FOLD	gAcc,4
	FOLD	gCount,4

	; seven arguments with an 8-byte struct return
	lea	rax,[castPt]
	mov	[proxyS.points],rax
	mov	dword [proxyS.count],1
	mov	eax,[c025]
	mov	[proxyS.radius],eax
	xor	eax,eax
	mov	[gAcc],eax
	mov	[gCount],eax
	fastcall b3World_CastShape,[worldId],pOrigin,proxyS,vTrans,qfS,CastCb,0
	mov	[res],rax
	FOLD	res,8
	FOLD	gAcc,4
	FOLD	gCount,4

	PHASE	_query

  ; ------------------------------------------------------------ tree
	fastcall b3DynamicTree_Create,treeS,16	; 80 bytes via hidden pointer
	xor	ebx,ebx
  .proxy:
	cvtsi2ss xmm0,ebx			; aabb {(i,0,0),(i+0.5,1,0.5)}
	movss	[tmpAabb],xmm0
	addss	xmm0,[c05]
	movss	[tmpAabb+12],xmm0
	xor	eax,eax
	mov	[tmpAabb+4],eax
	mov	[tmpAabb+8],eax
	mov	eax,[c10]
	mov	[tmpAabb+16],eax
	mov	eax,[c05]
	mov	[tmpAabb+20],eax
	mov	ecx,ebx
	mov	rax,1
	shl	rax,cl
	mov	[tmpCat],rax			; categoryBits = 1 << i
	lea	eax,[ebx+ebx*2+1]
	mov	[tmpUser],rax			; userData = i*3 + 1
	fastcall b3DynamicTree_CreateProxy,treeS,tmpAabb,[tmpCat],[tmpUser]
	mov	[res],eax
	FOLD	res,4
	inc	ebx
	cmp	ebx,5
	jb	.proxy

	xor	eax,eax
	mov	[gAcc],eax
	mov	[gCount],eax
	fastcall b3DynamicTree_Query,treeS,aabbQ,-1,0,TreeQueryCb,0
	mov	[res],rax
	FOLD	res,8
	FOLD	gAcc,4
	FOLD	gCount,4

	xor	eax,eax
	mov	[gAcc],eax
	mov	[gCount],eax
	fastcall b3DynamicTree_RayCast,treeS,rayTree,-1,0,TreeRayCb,0
	mov	[res],rax
	FOLD	res,8
	FOLD	gAcc,4
	FOLD	gCount,4

	fastcall b3DynamicTree_GetHeight,treeS
	mov	[res],eax
	FOLD	res,4
	fastcall b3DynamicTree_GetAreaRatio,treeS
	movss	dword [res],xmm0
	FOLD	res,4
	fastcall b3DynamicTree_GetRootBounds,res,treeS
	FOLD	res,24
	fastcall b3DynamicTree_GetCategoryBits,treeS,2	; uint64 in RAX
	mov	[res],rax
	FOLD	res,8

	fastcall b3DynamicTree_Rebuild,treeS,1
	mov	[res],eax
	FOLD	res,4
	fastcall b3DynamicTree_Destroy,treeS

	PHASE	_tree

  ; ----------------------------------------------------------- joint
	fastcall b3DefaultRevoluteJointDef,rjd	; padded; not folded
	mov	rax,[bodyIds+8]
	mov	[rjd.base.bodyIdA],rax
	mov	rax,[bodyIds+16]
	mov	[rjd.base.bodyIdB],rax
	mov	eax,[c05]
	mov	[rjd.base.localFrameA.p.y],eax
	mov	eax,[cM05]
	mov	[rjd.base.localFrameB.p.y],eax
	fastcall b3CreateRevoluteJoint,[worldId],rjd
	mov	[rjId],rax
	FOLD	rjId,8

	fastcall b3DefaultSphericalJointDef,sjd
	mov	rax,[bodyIds]
	mov	[sjd.base.bodyIdA],rax
	mov	rax,[bodyIds+8]
	mov	[sjd.base.bodyIdB],rax
	mov	eax,[c10]
	mov	[sjd.base.localFrameA.p.y],eax
	mov	eax,[cM10]
	mov	[sjd.base.localFrameB.p.y],eax
	fastcall b3CreateSphericalJoint,[worldId],sjd
	mov	[sjId],rax
	FOLD	sjId,8

	fastcall b3RevoluteJoint_EnableMotor,[rjId],1
	fastcall b3RevoluteJoint_SetMotorSpeed,[rjId],float dword [c15]
	fastcall b3RevoluteJoint_SetMaxMotorTorque,[rjId],float dword [c1000]
	mov	edi,30
  .step4:
	fastcall b3World_Step,[worldId],float dword [cDt],4
	dec	edi
	jnz	.step4

	fastcall b3RevoluteJoint_GetAngle,[rjId]
	movss	dword [res],xmm0
	FOLD	res,4
	fastcall b3RevoluteJoint_GetMotorTorque,[rjId]
	movss	dword [res],xmm0
	FOLD	res,4
	fastcall b3Joint_GetConstraintForce,res,[rjId]
	FOLD	res,12
	fastcall b3Joint_GetLocalFrameA,res,[rjId]	; 28 bytes via hidden pointer
	FOLD	res,28
	fastcall b3Joint_GetConstraintTuning,[rjId],outHertz,outDamp	; out-pointers
	FOLD	outHertz,4
	FOLD	outDamp,4
	fastcall b3Joint_IsValid,[rjId]
	mov	[res],al
	FOLD	res,1

	fastcall b3DestroyJoint,[sjId],1
	mov	edi,5
  .step5:
	fastcall b3World_Step,[worldId],float dword [cDt],4
	dec	edi
	jnz	.step5
	fastcall b3Body_GetTransform,res,[bodyIds+8]
	FOLD	res,28

	fastcall b3DestroyBody,[bodyIds+16]
	mov	edi,5
  .step6:
	fastcall b3World_Step,[worldId],float dword [cDt],4
	dec	edi
	jnz	.step6
	fastcall b3World_GetCounters,counters,[worldId]
	FOLD	counters,20

	fastcall b3DestroyWorld,[worldId]
	PHASE	_joint

	fastcall printf,_finalFmt,[gH]

	xor	eax,eax
	ret

endp

section '.rdata' data readable

  _phFmt db '%-6s %08X',10,0
  _finalFmt db 'FINAL  %08X',10,0
  _math db 'math',0
  _geom db 'geom',0
  _world db 'world',0
  _query db 'query',0
  _tree db 'tree',0
  _joint db 'joint',0

  ; exactly representable float constants, mirroring api_check.c
  c025	dd 0.25
  c05	dd 0.5
  cM05	dd -0.5
  c075	dd 0.75
  c10	dd 1.0
  cM10	dd -1.0
  c15	dd 1.5
  c20	dd 2.0
  c25	dd 2.5
  c30	dd 3.0
  c50	dd 5.0
  c70	dd 7.0
  c80	dd 8.0
  c100	dd 10.0
  c1000 dd 100.0
  cDt	dd 0.015625	; 1/64
  cOneF dd 1.0

  vAxisX  dd 1.0, 0.0, 0.0
  vAxisY  dd 0.0, 1.0, 0.0
  vOrigin dd 0.5, 1.0, 1.5
  vA	  dd 0.25, 0.5, 0.75
  vB	  dd 2.0, 1.0, 0.0
  vC	  dd 1.0, 1.0, 1.0
  vP1	  dd 0.0, 0.0, 0.0
  vQ1	  dd 1.0, 0.0, 0.0
  vP2	  dd 0.5, 1.0, 0.0
  vQ2	  dd 0.5, -1.0, 2.0
  v123	  dd 1.0, 2.0, 3.0
  matIdent dd 1.0,0.0,0.0, 0.0,1.0,0.0, 0.0,0.0,1.0

  tBox	  dd 1.0,2.0,3.0, 0.0,0.0,0.0,1.0	; b3Transform
  tSph	  dd 1.0,0.0,0.0, 0.0,0.0,0.0,1.0
  sphereS dd 0.25,0.5,0.75, 0.5			; b3Sphere
  raySph  dd 0.25,3.0,0.75, 0.0,-6.0,0.0, 1.0	; b3RayCastInput
  ptA	  dd 0.0, 0.0, 0.0
  ptB	  dd 1.5, 0.0, 0.0

  shSphere  dd 0.0,0.0,0.0, 0.5 		; b3Sphere on the body
  shCapsule dd 0.0,-0.25,0.0, 0.0,0.25,0.0, 0.25 ; b3Capsule
  vForce  dd 10.0, 0.0, 0.0
  pAt	  dd 0.0, 0.5, 0.0
  vWind   dd 2.0, 0.0, 0.0

  pOrigin dd 0.25, 10.0, 0.0
  vTrans  dd 0.0, -20.0, 0.0
  aabbBig dd -20.0,-5.0,-20.0, 20.0,20.0,20.0
  castPt  dd 0.0, 0.0, 0.0

  aabbQ   dd 0.25,0.25,0.0, 2.75,0.75,0.5
  rayTree dd -1.0,0.25,0.25, 6.0,0.0,0.0, 1.0

section '.data' data readable writeable

  gH dd B3_HASH_INIT
  gAcc dd 0
  gCount dd 0

  res:	rb 512			; untyped result scratch, sized per use
  worldId dd ?
	rb 4
  groundId dq ?
  bodyIds rq 3
  shapeSphereId dq ?
  rjId dq ?
  sjId dq ?
  tmpCat dq ?
  tmpUser dq ?
  tmpAabb rd 6
  outHertz dd ?
  outDamp dd ?

  wdef b3WorldDef
  bdef b3BodyDef
  sdef b3ShapeDef
  rjd b3RevoluteJointDef
  sjd b3SphericalJointDef
  din b3DistanceInput
  cacheS b3SimplexCache
  proxyS b3ShapeProxy
  counters b3Counters
  qfS b3QueryFilter
  treeS b3DynamicTree
  boxB b3BoxHull
  boxT b3BoxHull
  boxG b3BoxHull
  boxC b3BoxHull
