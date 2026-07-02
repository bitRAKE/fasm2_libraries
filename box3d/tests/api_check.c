// ABI conformance reference for the fasm2 bindings.
//
// Drives a deterministic sequence of Box3D calls chosen to cover every
// distinct calling-convention shape in the C interface, folding every
// result into the library's own b3Hash. api_check.asm performs the
// identical sequence through the fasm2 bindings; both link the same
// box3d import library, so the printed hashes must match bit for bit.
// A divergence pinpoints an ABI misunderstanding in the bindings
// (hidden-pointer returns, by-reference struct arguments, float register
// slots, stack spill, bool returns, callback conventions).
//
// Shapes covered:
//   returns: bool (AL), int, float (XMM0), 4-byte struct (b3WorldId),
//     8-byte int struct (b3BodyId), 8-byte float-pair struct (b3CosSin),
//     8-byte struct from a 6-arg call (b3TreeStats), pointer, and
//     hidden-pointer returns of 12/16/24/28/36/48/52/64/80/104/112/144/
//     152/200/440 bytes
//   params: ints/ids in GP slots, floats in XMM slots 2..4, floats and
//     bools on the stack (5th+ argument), structs >8 bytes by reference,
//     out-pointers, 5..8 argument calls with hidden pointers shifting
//     everything right
//   callbacks: Box3D calling back into this module with mixed
//     GP/XMM/by-reference arguments, returning float and bool
//
// All float inputs are exactly representable in binary so the assembler
// and the C compiler cannot disagree on constant conversion. The world
// runs one worker; nothing time-based is hashed.
//
// Structs returned by value carry indeterminate padding bytes (C11 6.2.6.1;
// a {0} initializer need not zero padding, and the return-temp copy brings
// the callee's stack garbage along). Folds therefore cover only padding-free
// byte ranges. The box hulls are the exception: Box3D pads them explicitly
// because hull identity is a content hash, so their full bytes are stable.

#include <stdio.h>
#include <string.h>
#include "box3d/box3d.h"

static uint32_t H = B3_HASH_INIT;

static void fold( const void* p, int n )
{
	H = b3Hash( H, (const uint8_t*)p, n );
}

static void phase( const char* name )
{
	printf( "%-6s %08X\n", name, H );
}

// order-independent accumulator for callbacks that may see hits in any order
static uint32_t g_acc;
static uint32_t g_count;

static float CastCb( b3ShapeId shapeId, b3Pos point, b3Vec3 normal, float fraction, uint64_t userMaterialId,
					 int triangleIndex, int childIndex, void* context )
{
	(void)point, (void)normal, (void)userMaterialId, (void)triangleIndex, (void)childIndex, (void)context;
	uint32_t bits;
	memcpy( &bits, &fraction, 4 );
	g_acc += bits + (uint32_t)shapeId.index1;
	g_count += 1;
	return 1.0f; // continue
}

static bool OverlapCb( b3ShapeId shapeId, void* context )
{
	(void)context;
	g_acc += (uint32_t)shapeId.index1;
	g_count += 1;
	return true;
}

static bool TreeQueryCb( int proxyId, uint64_t userData, void* context )
{
	(void)proxyId, (void)context;
	g_acc += (uint32_t)userData;
	g_count += 1;
	return true;
}

static float TreeRayCb( const b3RayCastInput* input, int proxyId, uint64_t userData, void* context )
{
	(void)proxyId, (void)context;
	g_acc += (uint32_t)userData;
	g_count += 1;
	return input->maxFraction; // continue without clipping
}

int main( void )
{
	// ---------------------------------------------------------- math
	{
		float f = b3Atan2( 0.5f, 1.5f );
		fold( &f, 4 );

		b3CosSin cs = b3ComputeCosSin( 0.75f ); // 8-byte float pair in RAX
		fold( &cs, 8 );

		b3Vec3 ax = { 1.0f, 0.0f, 0.0f };
		b3Vec3 ay = { 0.0f, 1.0f, 0.0f };
		b3Quat q = b3ComputeQuatBetweenUnitVectors( ax, ay );
		fold( &q, 16 );

		b3Vec3 origin = { 0.5f, 1.0f, 1.5f };
		b3Matrix3 st = b3Steiner( 2.5f, origin ); // float + by-ref, 36-byte return
		fold( &st, 36 );

		b3Vec3 a = { 0.25f, 0.5f, 0.75f };
		b3Vec3 b = { 2.0f, 1.0f, 0.0f };
		b3Vec3 c = { 1.0f, 1.0f, 1.0f };
		b3Vec3 p = b3PointToSegmentDistance( a, b, c );
		fold( &p, 12 );

		// hidden pointer + four by-ref arguments: the last lands on the stack
		b3Vec3 p1 = { 0.0f, 0.0f, 0.0f };
		b3Vec3 q1 = { 1.0f, 0.0f, 0.0f };
		b3Vec3 p2 = { 0.5f, 1.0f, 0.0f };
		b3Vec3 q2 = { 0.5f, -1.0f, 2.0f };
		b3SegmentDistanceResult sd = b3SegmentDistance( p1, q1, p2, q2 );
		fold( &sd, 32 );

		b3Vec3 v = { 1.0f, 2.0f, 3.0f };
		uint8_t ok = b3IsValidVec3( v ) ? 1 : 0; // bool returns live in AL
		fold( &ok, 1 );

		b3Matrix3 ident = { { 1.0f, 0.0f, 0.0f }, { 0.0f, 1.0f, 0.0f }, { 0.0f, 0.0f, 1.0f } };
		b3Quat qm = b3MakeQuatFromMatrix( &ident );
		fold( &qm, 16 );

		phase( "math" );
	}

	// ------------------------------------------------------ geometry
	static b3BoxHull box, tbox, ground, cube;
	static b3Sphere sphere = { { 0.25f, 0.5f, 0.75f }, 0.5f };
	{
		box = b3MakeBoxHull( 0.5f, 0.75f, 1.0f ); // 440 bytes via hidden pointer
		fold( &box, sizeof( b3BoxHull ) );

		// hidden pointer + 3 floats + by-ref transform: 5th slot on the stack
		b3Transform t = { { 1.0f, 2.0f, 3.0f }, { { 0.0f, 0.0f, 0.0f }, 1.0f } };
		tbox = b3MakeTransformedBoxHull( 0.5f, 0.5f, 0.5f, t );
		fold( &tbox, sizeof( b3BoxHull ) );

		b3MassData md = b3ComputeHullMass( &box.base, 2.0f ); // ptr then float in slot 3
		fold( &md, 52 );

		b3Transform ts = { { 1.0f, 0.0f, 0.0f }, { { 0.0f, 0.0f, 0.0f }, 1.0f } };
		b3AABB aabb = b3ComputeSphereAABB( &sphere, ts );
		fold( &aabb, 24 );

		b3HullData* cyl = b3CreateCylinder( 2.0f, 0.5f, 0.25f, 8 ); // pointer return
		fold( cyl, cyl->byteCount );
		b3DestroyHull( cyl );

		b3RayCastInput ray = { { 0.25f, 3.0f, 0.75f }, { 0.0f, -6.0f, 0.0f }, 1.0f };
		b3CastOutput co = b3RayCastSphere( &sphere, &ray );
		fold( &co, 45 ); // through the hit bool; the last 3 bytes are padding

		static const b3Vec3 ptA = { 0.0f, 0.0f, 0.0f };
		static const b3Vec3 ptB = { 1.5f, 0.0f, 0.0f };
		b3DistanceInput din = { 0 };
		din.proxyA.points = &ptA;
		din.proxyA.count = 1;
		din.proxyA.radius = 0.5f;
		din.proxyB.points = &ptB;
		din.proxyB.count = 1;
		din.proxyB.radius = 0.25f;
		din.transform.q.s = 1.0f;
		din.useRadii = true;
		b3SimplexCache cache = { 0 };
		b3DistanceOutput dout = b3ShapeDistance( &din, &cache, NULL, 0 );
		fold( &dout, 48 );
		fold( &cache, 14 ); // metric, count, indices; 2 padding bytes follow

		phase( "geom" );
	}

	// --------------------------------------------------------- world
	b3WorldId world;
	b3BodyId bodySphere, bodyCapsule, bodyHull;
	b3ShapeId shapeSphere;
	{
		b3WorldDef wdef = b3DefaultWorldDef();
		wdef.workerCount = 1;
		fold( &wdef, 36 ); // gravity through maximumLinearSpeed; padding follows

		world = b3CreateWorld( &wdef ); // 4-byte struct returned in EAX
		fold( &world, 4 );

		uint8_t ok = b3World_IsValid( world ) ? 1 : 0;
		fold( &ok, 1 );

		b3BodyDef bdef = b3DefaultBodyDef();
		fold( &bdef, sizeof( b3BodyDef ) ); // b3BodyDef has no padding
		b3ShapeDef sdef = b3DefaultShapeDef();
		fold( &sdef.density, 8 );	    // density + explosionScale
		fold( &sdef.enableCustomFiltering, 8 ); // the eight bools

		bdef.position = (b3Pos){ 0.0f, -0.5f, 0.0f };
		b3BodyId groundBody = b3CreateBody( world, &bdef ); // 8-byte struct in RAX
		fold( &groundBody, 8 );
		ground = b3MakeBoxHull( 10.0f, 0.5f, 10.0f );
		b3ShapeId gs = b3CreateHullShape( groundBody, &sdef, &ground.base );
		fold( &gs, 8 );

		bdef.type = b3_dynamicBody;
		bdef.position = (b3Pos){ 0.0f, 3.0f, 0.0f };
		bodySphere = b3CreateBody( world, &bdef );
		fold( &bodySphere, 8 );
		b3Sphere s = { { 0.0f, 0.0f, 0.0f }, 0.5f };
		shapeSphere = b3CreateSphereShape( bodySphere, &sdef, &s );
		fold( &shapeSphere, 8 );

		bdef.position = (b3Pos){ 0.25f, 5.0f, 0.25f };
		bodyCapsule = b3CreateBody( world, &bdef );
		b3Capsule cap = { { 0.0f, -0.25f, 0.0f }, { 0.0f, 0.25f, 0.0f }, 0.25f };
		b3ShapeId cs = b3CreateCapsuleShape( bodyCapsule, &sdef, &cap );
		fold( &cs, 8 );

		bdef.position = (b3Pos){ -0.5f, 7.0f, 0.0f };
		bodyHull = b3CreateBody( world, &bdef );
		cube = b3MakeBoxHull( 0.5f, 0.5f, 0.5f );
		b3ShapeId hs = b3CreateHullShape( bodyHull, &sdef, &cube.base );
		fold( &hs, 8 );

		for ( int i = 0; i < 90; ++i )
		{
			b3World_Step( world, 0.015625f, 4 ); // 1/64, exactly representable
		}

		b3BodyId bodies[3] = { bodySphere, bodyCapsule, bodyHull };
		for ( int i = 0; i < 3; ++i )
		{
			b3WorldTransform t = b3Body_GetTransform( bodies[i] );
			fold( &t, 28 );
			b3Vec3 lv = b3Body_GetLinearVelocity( bodies[i] );
			fold( &lv, 12 );
			b3Vec3 av = b3Body_GetAngularVelocity( bodies[i] );
			fold( &av, 12 );
			float mass = b3Body_GetMass( bodies[i] );
			fold( &mass, 4 );
			b3MassData md = b3Body_GetMassData( bodies[i] );
			fold( &md, 52 );
			b3Matrix3 in = b3Body_GetLocalRotationalInertia( bodies[i] );
			fold( &in, 36 );
			uint8_t awake = b3Body_IsAwake( bodies[i] ) ? 1 : 0;
			fold( &awake, 1 );
		}

		b3Body_SetGravityScale( bodySphere, 0.5f );
		float gs2 = b3Body_GetGravityScale( bodySphere );
		fold( &gs2, 4 );

		b3Vec3 force = { 10.0f, 0.0f, 0.0f };
		b3Pos at = { 0.0f, 0.5f, 0.0f };
		b3Body_ApplyForce( bodySphere, force, at, true );
		for ( int i = 0; i < 30; ++i )
		{
			b3World_Step( world, 0.015625f, 4 );
		}
		b3WorldTransform t1 = b3Body_GetTransform( bodySphere );
		fold( &t1, 28 );

		b3Shape_SetFriction( shapeSphere, 0.75f );
		float fr = b3Shape_GetFriction( shapeSphere );
		fold( &fr, 4 );
		b3Filter fl = b3Shape_GetFilter( shapeSphere ); // 24 bytes via hidden pointer
		fold( &fl, 20 ); // through groupIndex; 4 padding bytes follow
		b3Shape_EnableContactEvents( shapeSphere, true );
		uint8_t ce = b3Shape_AreContactEventsEnabled( shapeSphere ) ? 1 : 0;
		fold( &ce, 1 );

		b3Counters cn = b3World_GetCounters( world ); // 200 bytes via hidden pointer
		fold( &cn, 20 );			      // first five counters only

		int awakeCount = b3World_GetAwakeBodyCount( world );
		fold( &awakeCount, 4 );
		b3Vec3 g = b3World_GetGravity( world );
		fold( &g, 12 );

		// id + by-ref + xmm2 + xmm3 + stack float + stack bool
		b3Vec3 wind = { 2.0f, 0.0f, 0.0f };
		b3Shape_ApplyWind( shapeSphere, wind, 0.5f, 0.25f, 8.0f, true );
		for ( int i = 0; i < 10; ++i )
		{
			b3World_Step( world, 0.015625f, 4 );
		}
		b3WorldTransform t2 = b3Body_GetTransform( bodySphere );
		fold( &t2, 28 );

		phase( "world" );
	}

	// --------------------------------------------------------- query
	{
		b3QueryFilter qf = b3DefaultQueryFilter();
		fold( &qf, 32 );

		// hidden pointer + world + two by-ref + by-ref filter: stack spill
		b3Pos origin = { 0.25f, 10.0f, 0.0f };
		b3Vec3 translation = { 0.0f, -20.0f, 0.0f };
		b3RayResult rr = b3World_CastRayClosest( world, origin, translation, qf );
		fold( &rr, 61 ); // through the hit bool; the last 3 bytes are padding

		g_acc = 0;
		g_count = 0;
		b3TreeStats st = b3World_CastRay( world, origin, translation, qf, CastCb, NULL );
		fold( &st, 8 ); // 8-byte struct returned in RAX
		fold( &g_acc, 4 );
		fold( &g_count, 4 );

		g_acc = 0;
		g_count = 0;
		b3AABB big = { { -20.0f, -5.0f, -20.0f }, { 20.0f, 20.0f, 20.0f } };
		b3TreeStats st2 = b3World_OverlapAABB( world, big, qf, OverlapCb, NULL );
		fold( &st2, 8 );
		fold( &g_acc, 4 );
		fold( &g_count, 4 );

		// seven arguments with a hidden-pointer-free 8-byte struct return
		static const b3Vec3 castPt = { 0.0f, 0.0f, 0.0f };
		b3ShapeProxy proxy = { &castPt, 1, 0.25f };
		g_acc = 0;
		g_count = 0;
		b3TreeStats st3 = b3World_CastShape( world, origin, &proxy, translation, qf, CastCb, NULL );
		fold( &st3, 8 );
		fold( &g_acc, 4 );
		fold( &g_count, 4 );

		phase( "query" );
	}

	// ---------------------------------------------------------- tree
	{
		b3DynamicTree tree = b3DynamicTree_Create( 16 ); // 80 bytes via hidden pointer
		for ( int i = 0; i < 5; ++i )
		{
			b3AABB aabb = { { (float)i, 0.0f, 0.0f }, { (float)i + 0.5f, 1.0f, 0.5f } };
			int proxy = b3DynamicTree_CreateProxy( &tree, aabb, 1ull << i, (uint64_t)( i * 3 + 1 ) );
			fold( &proxy, 4 );
		}

		g_acc = 0;
		g_count = 0;
		b3AABB q = { { 0.25f, 0.25f, 0.0f }, { 2.75f, 0.75f, 0.5f } };
		b3TreeStats st = b3DynamicTree_Query( &tree, q, ~0ull, false, TreeQueryCb, NULL );
		fold( &st, 8 );
		fold( &g_acc, 4 );
		fold( &g_count, 4 );

		g_acc = 0;
		g_count = 0;
		b3RayCastInput ray = { { -1.0f, 0.25f, 0.25f }, { 6.0f, 0.0f, 0.0f }, 1.0f };
		b3TreeStats st2 = b3DynamicTree_RayCast( &tree, &ray, ~0ull, false, TreeRayCb, NULL );
		fold( &st2, 8 );
		fold( &g_acc, 4 );
		fold( &g_count, 4 );

		int height = b3DynamicTree_GetHeight( &tree );
		fold( &height, 4 );
		float ratio = b3DynamicTree_GetAreaRatio( &tree );
		fold( &ratio, 4 );
		b3AABB root = b3DynamicTree_GetRootBounds( &tree );
		fold( &root, 24 );
		uint64_t cat = b3DynamicTree_GetCategoryBits( &tree, 2 ); // uint64 in RAX
		fold( &cat, 8 );

		int sorted = b3DynamicTree_Rebuild( &tree, true );
		fold( &sorted, 4 );
		b3DynamicTree_Destroy( &tree );

		phase( "tree" );
	}

	// --------------------------------------------------------- joint
	{
		b3RevoluteJointDef rjd = b3DefaultRevoluteJointDef(); // padded; not folded
		rjd.base.bodyIdA = bodyCapsule;
		rjd.base.bodyIdB = bodyHull;
		rjd.base.localFrameA.p = (b3Vec3){ 0.0f, 0.5f, 0.0f };
		rjd.base.localFrameB.p = (b3Vec3){ 0.0f, -0.5f, 0.0f };
		b3JointId rj = b3CreateRevoluteJoint( world, &rjd );
		fold( &rj, 8 );

		b3SphericalJointDef sjd = b3DefaultSphericalJointDef();
		sjd.base.bodyIdA = bodySphere;
		sjd.base.bodyIdB = bodyCapsule;
		sjd.base.localFrameA.p = (b3Vec3){ 0.0f, 1.0f, 0.0f };
		sjd.base.localFrameB.p = (b3Vec3){ 0.0f, -1.0f, 0.0f };
		b3JointId sj = b3CreateSphericalJoint( world, &sjd );
		fold( &sj, 8 );

		b3RevoluteJoint_EnableMotor( rj, true );
		b3RevoluteJoint_SetMotorSpeed( rj, 1.5f );
		b3RevoluteJoint_SetMaxMotorTorque( rj, 100.0f );
		for ( int i = 0; i < 30; ++i )
		{
			b3World_Step( world, 0.015625f, 4 );
		}

		float angle = b3RevoluteJoint_GetAngle( rj );
		fold( &angle, 4 );
		float torque = b3RevoluteJoint_GetMotorTorque( rj );
		fold( &torque, 4 );
		b3Vec3 cf = b3Joint_GetConstraintForce( rj );
		fold( &cf, 12 );
		b3Transform fa = b3Joint_GetLocalFrameA( rj ); // 28 bytes via hidden pointer
		fold( &fa, 28 );
		float hertz = 0.0f, damping = 0.0f;
		b3Joint_GetConstraintTuning( rj, &hertz, &damping ); // out-pointers
		fold( &hertz, 4 );
		fold( &damping, 4 );
		uint8_t jv = b3Joint_IsValid( rj ) ? 1 : 0;
		fold( &jv, 1 );

		b3DestroyJoint( sj, true );
		for ( int i = 0; i < 5; ++i )
		{
			b3World_Step( world, 0.015625f, 4 );
		}
		b3WorldTransform t = b3Body_GetTransform( bodyCapsule );
		fold( &t, 28 );

		b3DestroyBody( bodyHull );
		for ( int i = 0; i < 5; ++i )
		{
			b3World_Step( world, 0.015625f, 4 );
		}
		b3Counters cn = b3World_GetCounters( world );
		fold( &cn, 20 );

		b3DestroyWorld( world );
		phase( "joint" );
	}

	printf( "FINAL  %08X\n", H );
	return 0;
}
