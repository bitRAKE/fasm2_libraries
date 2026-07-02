; Box3D external symbol declarations for fasm2 (format MS64 COFF)
; Link the resulting object against box3d.lib (static library) or the
; box3d.dll import library. Symbols are declared only when used.
; Generated from the B3_API declarations in include/box3d.

if used b3Atan2
	extrn b3Atan2
end if
if used b3Body_ApplyAngularImpulse
	extrn b3Body_ApplyAngularImpulse
end if
if used b3Body_ApplyForce
	extrn b3Body_ApplyForce
end if
if used b3Body_ApplyForceToCenter
	extrn b3Body_ApplyForceToCenter
end if
if used b3Body_ApplyLinearImpulse
	extrn b3Body_ApplyLinearImpulse
end if
if used b3Body_ApplyLinearImpulseToCenter
	extrn b3Body_ApplyLinearImpulseToCenter
end if
if used b3Body_ApplyMassFromShapes
	extrn b3Body_ApplyMassFromShapes
end if
if used b3Body_ApplyTorque
	extrn b3Body_ApplyTorque
end if
if used b3Body_CastRay
	extrn b3Body_CastRay
end if
if used b3Body_CastShape
	extrn b3Body_CastShape
end if
if used b3Body_CollideMover
	extrn b3Body_CollideMover
end if
if used b3Body_ComputeAABB
	extrn b3Body_ComputeAABB
end if
if used b3Body_Disable
	extrn b3Body_Disable
end if
if used b3Body_Enable
	extrn b3Body_Enable
end if
if used b3Body_EnableContactRecycling
	extrn b3Body_EnableContactRecycling
end if
if used b3Body_EnableHitEvents
	extrn b3Body_EnableHitEvents
end if
if used b3Body_EnableSleep
	extrn b3Body_EnableSleep
end if
if used b3Body_GetAngularDamping
	extrn b3Body_GetAngularDamping
end if
if used b3Body_GetAngularVelocity
	extrn b3Body_GetAngularVelocity
end if
if used b3Body_GetClosestPoint
	extrn b3Body_GetClosestPoint
end if
if used b3Body_GetContactCapacity
	extrn b3Body_GetContactCapacity
end if
if used b3Body_GetContactData
	extrn b3Body_GetContactData
end if
if used b3Body_GetGravityScale
	extrn b3Body_GetGravityScale
end if
if used b3Body_GetInverseMass
	extrn b3Body_GetInverseMass
end if
if used b3Body_GetJointCount
	extrn b3Body_GetJointCount
end if
if used b3Body_GetJoints
	extrn b3Body_GetJoints
end if
if used b3Body_GetLinearDamping
	extrn b3Body_GetLinearDamping
end if
if used b3Body_GetLinearVelocity
	extrn b3Body_GetLinearVelocity
end if
if used b3Body_GetLocalCenterOfMass
	extrn b3Body_GetLocalCenterOfMass
end if
if used b3Body_GetLocalPoint
	extrn b3Body_GetLocalPoint
end if
if used b3Body_GetLocalPointVelocity
	extrn b3Body_GetLocalPointVelocity
end if
if used b3Body_GetLocalRotationalInertia
	extrn b3Body_GetLocalRotationalInertia
end if
if used b3Body_GetLocalVector
	extrn b3Body_GetLocalVector
end if
if used b3Body_GetMass
	extrn b3Body_GetMass
end if
if used b3Body_GetMassData
	extrn b3Body_GetMassData
end if
if used b3Body_GetMotionLocks
	extrn b3Body_GetMotionLocks
end if
if used b3Body_GetName
	extrn b3Body_GetName
end if
if used b3Body_GetPosition
	extrn b3Body_GetPosition
end if
if used b3Body_GetRotation
	extrn b3Body_GetRotation
end if
if used b3Body_GetShapeCount
	extrn b3Body_GetShapeCount
end if
if used b3Body_GetShapes
	extrn b3Body_GetShapes
end if
if used b3Body_GetSleepThreshold
	extrn b3Body_GetSleepThreshold
end if
if used b3Body_GetTransform
	extrn b3Body_GetTransform
end if
if used b3Body_GetType
	extrn b3Body_GetType
end if
if used b3Body_GetUserData
	extrn b3Body_GetUserData
end if
if used b3Body_GetWorld
	extrn b3Body_GetWorld
end if
if used b3Body_GetWorldCenterOfMass
	extrn b3Body_GetWorldCenterOfMass
end if
if used b3Body_GetWorldInverseRotationalInertia
	extrn b3Body_GetWorldInverseRotationalInertia
end if
if used b3Body_GetWorldPoint
	extrn b3Body_GetWorldPoint
end if
if used b3Body_GetWorldPointVelocity
	extrn b3Body_GetWorldPointVelocity
end if
if used b3Body_GetWorldVector
	extrn b3Body_GetWorldVector
end if
if used b3Body_IsAwake
	extrn b3Body_IsAwake
end if
if used b3Body_IsBullet
	extrn b3Body_IsBullet
end if
if used b3Body_IsContactRecyclingEnabled
	extrn b3Body_IsContactRecyclingEnabled
end if
if used b3Body_IsEnabled
	extrn b3Body_IsEnabled
end if
if used b3Body_IsSleepEnabled
	extrn b3Body_IsSleepEnabled
end if
if used b3Body_IsValid
	extrn b3Body_IsValid
end if
if used b3Body_OverlapShape
	extrn b3Body_OverlapShape
end if
if used b3Body_SetAngularDamping
	extrn b3Body_SetAngularDamping
end if
if used b3Body_SetAngularVelocity
	extrn b3Body_SetAngularVelocity
end if
if used b3Body_SetAwake
	extrn b3Body_SetAwake
end if
if used b3Body_SetBullet
	extrn b3Body_SetBullet
end if
if used b3Body_SetGravityScale
	extrn b3Body_SetGravityScale
end if
if used b3Body_SetLinearDamping
	extrn b3Body_SetLinearDamping
end if
if used b3Body_SetLinearVelocity
	extrn b3Body_SetLinearVelocity
end if
if used b3Body_SetMassData
	extrn b3Body_SetMassData
end if
if used b3Body_SetMotionLocks
	extrn b3Body_SetMotionLocks
end if
if used b3Body_SetName
	extrn b3Body_SetName
end if
if used b3Body_SetSleepThreshold
	extrn b3Body_SetSleepThreshold
end if
if used b3Body_SetTargetTransform
	extrn b3Body_SetTargetTransform
end if
if used b3Body_SetTransform
	extrn b3Body_SetTransform
end if
if used b3Body_SetType
	extrn b3Body_SetType
end if
if used b3Body_SetUserData
	extrn b3Body_SetUserData
end if
if used b3ClipVector
	extrn b3ClipVector
end if
if used b3CloneAndTransformHull
	extrn b3CloneAndTransformHull
end if
if used b3CloneHull
	extrn b3CloneHull
end if
if used b3CollideCapsuleAndSphere
	extrn b3CollideCapsuleAndSphere
end if
if used b3CollideCapsuleAndTriangle
	extrn b3CollideCapsuleAndTriangle
end if
if used b3CollideCapsules
	extrn b3CollideCapsules
end if
if used b3CollideHullAndCapsule
	extrn b3CollideHullAndCapsule
end if
if used b3CollideHullAndSphere
	extrn b3CollideHullAndSphere
end if
if used b3CollideHullAndTriangle
	extrn b3CollideHullAndTriangle
end if
if used b3CollideHulls
	extrn b3CollideHulls
end if
if used b3CollideSphereAndTriangle
	extrn b3CollideSphereAndTriangle
end if
if used b3CollideSpheres
	extrn b3CollideSpheres
end if
if used b3ComputeCapsuleAABB
	extrn b3ComputeCapsuleAABB
end if
if used b3ComputeCapsuleMass
	extrn b3ComputeCapsuleMass
end if
if used b3ComputeCompoundAABB
	extrn b3ComputeCompoundAABB
end if
if used b3ComputeCosSin
	extrn b3ComputeCosSin
end if
if used b3ComputeHeightFieldAABB
	extrn b3ComputeHeightFieldAABB
end if
if used b3ComputeHullAABB
	extrn b3ComputeHullAABB
end if
if used b3ComputeHullMass
	extrn b3ComputeHullMass
end if
if used b3ComputeMeshAABB
	extrn b3ComputeMeshAABB
end if
if used b3ComputeQuatBetweenUnitVectors
	extrn b3ComputeQuatBetweenUnitVectors
end if
if used b3ComputeSphereAABB
	extrn b3ComputeSphereAABB
end if
if used b3ComputeSphereMass
	extrn b3ComputeSphereMass
end if
if used b3Contact_GetData
	extrn b3Contact_GetData
end if
if used b3Contact_IsValid
	extrn b3Contact_IsValid
end if
if used b3ConvertBytesToCompound
	extrn b3ConvertBytesToCompound
end if
if used b3ConvertCompoundToBytes
	extrn b3ConvertCompoundToBytes
end if
if used b3CreateBody
	extrn b3CreateBody
end if
if used b3CreateBoxMesh
	extrn b3CreateBoxMesh
end if
if used b3CreateCapsuleShape
	extrn b3CreateCapsuleShape
end if
if used b3CreateCompound
	extrn b3CreateCompound
end if
if used b3CreateCompoundShape
	extrn b3CreateCompoundShape
end if
if used b3CreateCone
	extrn b3CreateCone
end if
if used b3CreateCylinder
	extrn b3CreateCylinder
end if
if used b3CreateDistanceJoint
	extrn b3CreateDistanceJoint
end if
if used b3CreateFilterJoint
	extrn b3CreateFilterJoint
end if
if used b3CreateGrid
	extrn b3CreateGrid
end if
if used b3CreateGridMesh
	extrn b3CreateGridMesh
end if
if used b3CreateHeightField
	extrn b3CreateHeightField
end if
if used b3CreateHeightFieldShape
	extrn b3CreateHeightFieldShape
end if
if used b3CreateHollowBoxMesh
	extrn b3CreateHollowBoxMesh
end if
if used b3CreateHull
	extrn b3CreateHull
end if
if used b3CreateHullShape
	extrn b3CreateHullShape
end if
if used b3CreateMesh
	extrn b3CreateMesh
end if
if used b3CreateMeshShape
	extrn b3CreateMeshShape
end if
if used b3CreateMotorJoint
	extrn b3CreateMotorJoint
end if
if used b3CreateParallelJoint
	extrn b3CreateParallelJoint
end if
if used b3CreatePlatformMesh
	extrn b3CreatePlatformMesh
end if
if used b3CreatePrismaticJoint
	extrn b3CreatePrismaticJoint
end if
if used b3CreateRecording
	extrn b3CreateRecording
end if
if used b3CreateRevoluteJoint
	extrn b3CreateRevoluteJoint
end if
if used b3CreateRock
	extrn b3CreateRock
end if
if used b3CreateSphereShape
	extrn b3CreateSphereShape
end if
if used b3CreateSphericalJoint
	extrn b3CreateSphericalJoint
end if
if used b3CreateTorusMesh
	extrn b3CreateTorusMesh
end if
if used b3CreateTransformedHullShape
	extrn b3CreateTransformedHullShape
end if
if used b3CreateWave
	extrn b3CreateWave
end if
if used b3CreateWaveMesh
	extrn b3CreateWaveMesh
end if
if used b3CreateWeldJoint
	extrn b3CreateWeldJoint
end if
if used b3CreateWheelJoint
	extrn b3CreateWheelJoint
end if
if used b3CreateWorld
	extrn b3CreateWorld
end if
if used b3DefaultBodyDef
	extrn b3DefaultBodyDef
end if
if used b3DefaultDebugDraw
	extrn b3DefaultDebugDraw
end if
if used b3DefaultDistanceJointDef
	extrn b3DefaultDistanceJointDef
end if
if used b3DefaultExplosionDef
	extrn b3DefaultExplosionDef
end if
if used b3DefaultFilter
	extrn b3DefaultFilter
end if
if used b3DefaultFilterJointDef
	extrn b3DefaultFilterJointDef
end if
if used b3DefaultMotorJointDef
	extrn b3DefaultMotorJointDef
end if
if used b3DefaultParallelJointDef
	extrn b3DefaultParallelJointDef
end if
if used b3DefaultPrismaticJointDef
	extrn b3DefaultPrismaticJointDef
end if
if used b3DefaultQueryFilter
	extrn b3DefaultQueryFilter
end if
if used b3DefaultRevoluteJointDef
	extrn b3DefaultRevoluteJointDef
end if
if used b3DefaultShapeDef
	extrn b3DefaultShapeDef
end if
if used b3DefaultSphericalJointDef
	extrn b3DefaultSphericalJointDef
end if
if used b3DefaultSurfaceMaterial
	extrn b3DefaultSurfaceMaterial
end if
if used b3DefaultWeldJointDef
	extrn b3DefaultWeldJointDef
end if
if used b3DefaultWheelJointDef
	extrn b3DefaultWheelJointDef
end if
if used b3DefaultWorldDef
	extrn b3DefaultWorldDef
end if
if used b3DestroyBody
	extrn b3DestroyBody
end if
if used b3DestroyCompound
	extrn b3DestroyCompound
end if
if used b3DestroyHeightField
	extrn b3DestroyHeightField
end if
if used b3DestroyHull
	extrn b3DestroyHull
end if
if used b3DestroyJoint
	extrn b3DestroyJoint
end if
if used b3DestroyMesh
	extrn b3DestroyMesh
end if
if used b3DestroyRecording
	extrn b3DestroyRecording
end if
if used b3DestroyShape
	extrn b3DestroyShape
end if
if used b3DestroyWorld
	extrn b3DestroyWorld
end if
if used b3DistanceJoint_EnableLimit
	extrn b3DistanceJoint_EnableLimit
end if
if used b3DistanceJoint_EnableMotor
	extrn b3DistanceJoint_EnableMotor
end if
if used b3DistanceJoint_EnableSpring
	extrn b3DistanceJoint_EnableSpring
end if
if used b3DistanceJoint_GetCurrentLength
	extrn b3DistanceJoint_GetCurrentLength
end if
if used b3DistanceJoint_GetLength
	extrn b3DistanceJoint_GetLength
end if
if used b3DistanceJoint_GetMaxLength
	extrn b3DistanceJoint_GetMaxLength
end if
if used b3DistanceJoint_GetMaxMotorForce
	extrn b3DistanceJoint_GetMaxMotorForce
end if
if used b3DistanceJoint_GetMinLength
	extrn b3DistanceJoint_GetMinLength
end if
if used b3DistanceJoint_GetMotorForce
	extrn b3DistanceJoint_GetMotorForce
end if
if used b3DistanceJoint_GetMotorSpeed
	extrn b3DistanceJoint_GetMotorSpeed
end if
if used b3DistanceJoint_GetSpringDampingRatio
	extrn b3DistanceJoint_GetSpringDampingRatio
end if
if used b3DistanceJoint_GetSpringForceRange
	extrn b3DistanceJoint_GetSpringForceRange
end if
if used b3DistanceJoint_GetSpringHertz
	extrn b3DistanceJoint_GetSpringHertz
end if
if used b3DistanceJoint_IsLimitEnabled
	extrn b3DistanceJoint_IsLimitEnabled
end if
if used b3DistanceJoint_IsMotorEnabled
	extrn b3DistanceJoint_IsMotorEnabled
end if
if used b3DistanceJoint_IsSpringEnabled
	extrn b3DistanceJoint_IsSpringEnabled
end if
if used b3DistanceJoint_SetLength
	extrn b3DistanceJoint_SetLength
end if
if used b3DistanceJoint_SetLengthRange
	extrn b3DistanceJoint_SetLengthRange
end if
if used b3DistanceJoint_SetMaxMotorForce
	extrn b3DistanceJoint_SetMaxMotorForce
end if
if used b3DistanceJoint_SetMotorSpeed
	extrn b3DistanceJoint_SetMotorSpeed
end if
if used b3DistanceJoint_SetSpringDampingRatio
	extrn b3DistanceJoint_SetSpringDampingRatio
end if
if used b3DistanceJoint_SetSpringForceRange
	extrn b3DistanceJoint_SetSpringForceRange
end if
if used b3DistanceJoint_SetSpringHertz
	extrn b3DistanceJoint_SetSpringHertz
end if
if used b3DumpHeightData
	extrn b3DumpHeightData
end if
if used b3DynamicTree_BoxCast
	extrn b3DynamicTree_BoxCast
end if
if used b3DynamicTree_Create
	extrn b3DynamicTree_Create
end if
if used b3DynamicTree_CreateProxy
	extrn b3DynamicTree_CreateProxy
end if
if used b3DynamicTree_Destroy
	extrn b3DynamicTree_Destroy
end if
if used b3DynamicTree_DestroyProxy
	extrn b3DynamicTree_DestroyProxy
end if
if used b3DynamicTree_EnlargeProxy
	extrn b3DynamicTree_EnlargeProxy
end if
if used b3DynamicTree_GetAreaRatio
	extrn b3DynamicTree_GetAreaRatio
end if
if used b3DynamicTree_GetByteCount
	extrn b3DynamicTree_GetByteCount
end if
if used b3DynamicTree_GetCategoryBits
	extrn b3DynamicTree_GetCategoryBits
end if
if used b3DynamicTree_GetHeight
	extrn b3DynamicTree_GetHeight
end if
if used b3DynamicTree_GetProxyCount
	extrn b3DynamicTree_GetProxyCount
end if
if used b3DynamicTree_GetRootBounds
	extrn b3DynamicTree_GetRootBounds
end if
if used b3DynamicTree_Load
	extrn b3DynamicTree_Load
end if
if used b3DynamicTree_MoveProxy
	extrn b3DynamicTree_MoveProxy
end if
if used b3DynamicTree_Query
	extrn b3DynamicTree_Query
end if
if used b3DynamicTree_QueryClosest
	extrn b3DynamicTree_QueryClosest
end if
if used b3DynamicTree_RayCast
	extrn b3DynamicTree_RayCast
end if
if used b3DynamicTree_Rebuild
	extrn b3DynamicTree_Rebuild
end if
if used b3DynamicTree_Save
	extrn b3DynamicTree_Save
end if
if used b3DynamicTree_SetCategoryBits
	extrn b3DynamicTree_SetCategoryBits
end if
if used b3DynamicTree_Validate
	extrn b3DynamicTree_Validate
end if
if used b3DynamicTree_ValidateNoEnlarged
	extrn b3DynamicTree_ValidateNoEnlarged
end if
if used b3GetByteCount
	extrn b3GetByteCount
end if
if used b3GetCompoundCapsule
	extrn b3GetCompoundCapsule
end if
if used b3GetCompoundChild
	extrn b3GetCompoundChild
end if
if used b3GetCompoundHull
	extrn b3GetCompoundHull
end if
if used b3GetCompoundMaterials
	extrn b3GetCompoundMaterials
end if
if used b3GetCompoundMesh
	extrn b3GetCompoundMesh
end if
if used b3GetCompoundSphere
	extrn b3GetCompoundSphere
end if
if used b3GetGraphColor
	extrn b3GetGraphColor
end if
if used b3GetHeight
	extrn b3GetHeight
end if
if used b3GetLengthUnitsPerMeter
	extrn b3GetLengthUnitsPerMeter
end if
if used b3GetMaxWorldCount
	extrn b3GetMaxWorldCount
end if
if used b3GetMilliseconds
	extrn b3GetMilliseconds
end if
if used b3GetMillisecondsAndReset
	extrn b3GetMillisecondsAndReset
end if
if used b3GetStallThreshold
	extrn b3GetStallThreshold
end if
if used b3GetSweepTransform
	extrn b3GetSweepTransform
end if
if used b3GetTicks
	extrn b3GetTicks
end if
if used b3GetVersion
	extrn b3GetVersion
end if
if used b3GetWorldCount
	extrn b3GetWorldCount
end if
if used b3Hash
	extrn b3Hash
end if
if used b3InternalAssert
	extrn b3InternalAssert
end if
if used b3IsBoundedAABB
	extrn b3IsBoundedAABB
end if
if used b3IsDoublePrecision
	extrn b3IsDoublePrecision
end if
if used b3IsSaneAABB
	extrn b3IsSaneAABB
end if
if used b3IsValidAABB
	extrn b3IsValidAABB
end if
if used b3IsValidFloat
	extrn b3IsValidFloat
end if
if used b3IsValidMatrix3
	extrn b3IsValidMatrix3
end if
if used b3IsValidPlane
	extrn b3IsValidPlane
end if
if used b3IsValidPosition
	extrn b3IsValidPosition
end if
if used b3IsValidQuat
	extrn b3IsValidQuat
end if
if used b3IsValidRay
	extrn b3IsValidRay
end if
if used b3IsValidTransform
	extrn b3IsValidTransform
end if
if used b3IsValidVec3
	extrn b3IsValidVec3
end if
if used b3IsValidWorldTransform
	extrn b3IsValidWorldTransform
end if
if used b3Joint_GetAngularSeparation
	extrn b3Joint_GetAngularSeparation
end if
if used b3Joint_GetBodyA
	extrn b3Joint_GetBodyA
end if
if used b3Joint_GetBodyB
	extrn b3Joint_GetBodyB
end if
if used b3Joint_GetCollideConnected
	extrn b3Joint_GetCollideConnected
end if
if used b3Joint_GetConstraintForce
	extrn b3Joint_GetConstraintForce
end if
if used b3Joint_GetConstraintTorque
	extrn b3Joint_GetConstraintTorque
end if
if used b3Joint_GetConstraintTuning
	extrn b3Joint_GetConstraintTuning
end if
if used b3Joint_GetForceThreshold
	extrn b3Joint_GetForceThreshold
end if
if used b3Joint_GetLinearSeparation
	extrn b3Joint_GetLinearSeparation
end if
if used b3Joint_GetLocalFrameA
	extrn b3Joint_GetLocalFrameA
end if
if used b3Joint_GetLocalFrameB
	extrn b3Joint_GetLocalFrameB
end if
if used b3Joint_GetTorqueThreshold
	extrn b3Joint_GetTorqueThreshold
end if
if used b3Joint_GetType
	extrn b3Joint_GetType
end if
if used b3Joint_GetUserData
	extrn b3Joint_GetUserData
end if
if used b3Joint_GetWorld
	extrn b3Joint_GetWorld
end if
if used b3Joint_IsValid
	extrn b3Joint_IsValid
end if
if used b3Joint_SetCollideConnected
	extrn b3Joint_SetCollideConnected
end if
if used b3Joint_SetConstraintTuning
	extrn b3Joint_SetConstraintTuning
end if
if used b3Joint_SetForceThreshold
	extrn b3Joint_SetForceThreshold
end if
if used b3Joint_SetLocalFrameA
	extrn b3Joint_SetLocalFrameA
end if
if used b3Joint_SetLocalFrameB
	extrn b3Joint_SetLocalFrameB
end if
if used b3Joint_SetTorqueThreshold
	extrn b3Joint_SetTorqueThreshold
end if
if used b3Joint_SetUserData
	extrn b3Joint_SetUserData
end if
if used b3Joint_WakeBodies
	extrn b3Joint_WakeBodies
end if
if used b3LineDistance
	extrn b3LineDistance
end if
if used b3LoadHeightField
	extrn b3LoadHeightField
end if
if used b3LoadRecordingFromFile
	extrn b3LoadRecordingFromFile
end if
if used b3MakeBoxHull
	extrn b3MakeBoxHull
end if
if used b3MakeCubeHull
	extrn b3MakeCubeHull
end if
if used b3MakeOffsetBoxHull
	extrn b3MakeOffsetBoxHull
end if
if used b3MakeQuatFromMatrix
	extrn b3MakeQuatFromMatrix
end if
if used b3MakeScaledBoxHull
	extrn b3MakeScaledBoxHull
end if
if used b3MakeTransformedBoxHull
	extrn b3MakeTransformedBoxHull
end if
if used b3MotorJoint_GetAngularDampingRatio
	extrn b3MotorJoint_GetAngularDampingRatio
end if
if used b3MotorJoint_GetAngularHertz
	extrn b3MotorJoint_GetAngularHertz
end if
if used b3MotorJoint_GetAngularVelocity
	extrn b3MotorJoint_GetAngularVelocity
end if
if used b3MotorJoint_GetLinearDampingRatio
	extrn b3MotorJoint_GetLinearDampingRatio
end if
if used b3MotorJoint_GetLinearHertz
	extrn b3MotorJoint_GetLinearHertz
end if
if used b3MotorJoint_GetLinearVelocity
	extrn b3MotorJoint_GetLinearVelocity
end if
if used b3MotorJoint_GetMaxSpringForce
	extrn b3MotorJoint_GetMaxSpringForce
end if
if used b3MotorJoint_GetMaxSpringTorque
	extrn b3MotorJoint_GetMaxSpringTorque
end if
if used b3MotorJoint_GetMaxVelocityForce
	extrn b3MotorJoint_GetMaxVelocityForce
end if
if used b3MotorJoint_GetMaxVelocityTorque
	extrn b3MotorJoint_GetMaxVelocityTorque
end if
if used b3MotorJoint_SetAngularDampingRatio
	extrn b3MotorJoint_SetAngularDampingRatio
end if
if used b3MotorJoint_SetAngularHertz
	extrn b3MotorJoint_SetAngularHertz
end if
if used b3MotorJoint_SetAngularVelocity
	extrn b3MotorJoint_SetAngularVelocity
end if
if used b3MotorJoint_SetLinearDampingRatio
	extrn b3MotorJoint_SetLinearDampingRatio
end if
if used b3MotorJoint_SetLinearHertz
	extrn b3MotorJoint_SetLinearHertz
end if
if used b3MotorJoint_SetLinearVelocity
	extrn b3MotorJoint_SetLinearVelocity
end if
if used b3MotorJoint_SetMaxSpringForce
	extrn b3MotorJoint_SetMaxSpringForce
end if
if used b3MotorJoint_SetMaxSpringTorque
	extrn b3MotorJoint_SetMaxSpringTorque
end if
if used b3MotorJoint_SetMaxVelocityForce
	extrn b3MotorJoint_SetMaxVelocityForce
end if
if used b3MotorJoint_SetMaxVelocityTorque
	extrn b3MotorJoint_SetMaxVelocityTorque
end if
if used b3OverlapCapsule
	extrn b3OverlapCapsule
end if
if used b3OverlapCompound
	extrn b3OverlapCompound
end if
if used b3OverlapHeightField
	extrn b3OverlapHeightField
end if
if used b3OverlapHull
	extrn b3OverlapHull
end if
if used b3OverlapMesh
	extrn b3OverlapMesh
end if
if used b3OverlapSphere
	extrn b3OverlapSphere
end if
if used b3ParallelJoint_GetMaxTorque
	extrn b3ParallelJoint_GetMaxTorque
end if
if used b3ParallelJoint_GetSpringDampingRatio
	extrn b3ParallelJoint_GetSpringDampingRatio
end if
if used b3ParallelJoint_GetSpringHertz
	extrn b3ParallelJoint_GetSpringHertz
end if
if used b3ParallelJoint_SetMaxTorque
	extrn b3ParallelJoint_SetMaxTorque
end if
if used b3ParallelJoint_SetSpringDampingRatio
	extrn b3ParallelJoint_SetSpringDampingRatio
end if
if used b3ParallelJoint_SetSpringHertz
	extrn b3ParallelJoint_SetSpringHertz
end if
if used b3PointToSegmentDistance
	extrn b3PointToSegmentDistance
end if
if used b3PrismaticJoint_EnableLimit
	extrn b3PrismaticJoint_EnableLimit
end if
if used b3PrismaticJoint_EnableMotor
	extrn b3PrismaticJoint_EnableMotor
end if
if used b3PrismaticJoint_EnableSpring
	extrn b3PrismaticJoint_EnableSpring
end if
if used b3PrismaticJoint_GetLowerLimit
	extrn b3PrismaticJoint_GetLowerLimit
end if
if used b3PrismaticJoint_GetMaxMotorForce
	extrn b3PrismaticJoint_GetMaxMotorForce
end if
if used b3PrismaticJoint_GetMotorForce
	extrn b3PrismaticJoint_GetMotorForce
end if
if used b3PrismaticJoint_GetMotorSpeed
	extrn b3PrismaticJoint_GetMotorSpeed
end if
if used b3PrismaticJoint_GetSpeed
	extrn b3PrismaticJoint_GetSpeed
end if
if used b3PrismaticJoint_GetSpringDampingRatio
	extrn b3PrismaticJoint_GetSpringDampingRatio
end if
if used b3PrismaticJoint_GetSpringHertz
	extrn b3PrismaticJoint_GetSpringHertz
end if
if used b3PrismaticJoint_GetTargetTranslation
	extrn b3PrismaticJoint_GetTargetTranslation
end if
if used b3PrismaticJoint_GetTranslation
	extrn b3PrismaticJoint_GetTranslation
end if
if used b3PrismaticJoint_GetUpperLimit
	extrn b3PrismaticJoint_GetUpperLimit
end if
if used b3PrismaticJoint_IsLimitEnabled
	extrn b3PrismaticJoint_IsLimitEnabled
end if
if used b3PrismaticJoint_IsMotorEnabled
	extrn b3PrismaticJoint_IsMotorEnabled
end if
if used b3PrismaticJoint_IsSpringEnabled
	extrn b3PrismaticJoint_IsSpringEnabled
end if
if used b3PrismaticJoint_SetLimits
	extrn b3PrismaticJoint_SetLimits
end if
if used b3PrismaticJoint_SetMaxMotorForce
	extrn b3PrismaticJoint_SetMaxMotorForce
end if
if used b3PrismaticJoint_SetMotorSpeed
	extrn b3PrismaticJoint_SetMotorSpeed
end if
if used b3PrismaticJoint_SetSpringDampingRatio
	extrn b3PrismaticJoint_SetSpringDampingRatio
end if
if used b3PrismaticJoint_SetSpringHertz
	extrn b3PrismaticJoint_SetSpringHertz
end if
if used b3PrismaticJoint_SetTargetTranslation
	extrn b3PrismaticJoint_SetTargetTranslation
end if
if used b3QueryCompound
	extrn b3QueryCompound
end if
if used b3QueryHeightField
	extrn b3QueryHeightField
end if
if used b3QueryMesh
	extrn b3QueryMesh
end if
if used b3RayCastCapsule
	extrn b3RayCastCapsule
end if
if used b3RayCastCompound
	extrn b3RayCastCompound
end if
if used b3RayCastHeightField
	extrn b3RayCastHeightField
end if
if used b3RayCastHollowSphere
	extrn b3RayCastHollowSphere
end if
if used b3RayCastHull
	extrn b3RayCastHull
end if
if used b3RayCastMesh
	extrn b3RayCastMesh
end if
if used b3RayCastSphere
	extrn b3RayCastSphere
end if
if used b3ReadBinaryFile
	extrn b3ReadBinaryFile
end if
if used b3RecPlayer_Create
	extrn b3RecPlayer_Create
end if
if used b3RecPlayer_Destroy
	extrn b3RecPlayer_Destroy
end if
if used b3RecPlayer_DrawFrameQueries
	extrn b3RecPlayer_DrawFrameQueries
end if
if used b3RecPlayer_GetBodyCount
	extrn b3RecPlayer_GetBodyCount
end if
if used b3RecPlayer_GetBodyId
	extrn b3RecPlayer_GetBodyId
end if
if used b3RecPlayer_GetDivergeFrame
	extrn b3RecPlayer_GetDivergeFrame
end if
if used b3RecPlayer_GetFrame
	extrn b3RecPlayer_GetFrame
end if
if used b3RecPlayer_GetFrameCount
	extrn b3RecPlayer_GetFrameCount
end if
if used b3RecPlayer_GetFrameQuery
	extrn b3RecPlayer_GetFrameQuery
end if
if used b3RecPlayer_GetFrameQueryCount
	extrn b3RecPlayer_GetFrameQueryCount
end if
if used b3RecPlayer_GetFrameQueryHit
	extrn b3RecPlayer_GetFrameQueryHit
end if
if used b3RecPlayer_GetInfo
	extrn b3RecPlayer_GetInfo
end if
if used b3RecPlayer_GetKeyframeBudget
	extrn b3RecPlayer_GetKeyframeBudget
end if
if used b3RecPlayer_GetKeyframeBytes
	extrn b3RecPlayer_GetKeyframeBytes
end if
if used b3RecPlayer_GetKeyframeInterval
	extrn b3RecPlayer_GetKeyframeInterval
end if
if used b3RecPlayer_GetKeyframeMinInterval
	extrn b3RecPlayer_GetKeyframeMinInterval
end if
if used b3RecPlayer_GetWorldId
	extrn b3RecPlayer_GetWorldId
end if
if used b3RecPlayer_HasDiverged
	extrn b3RecPlayer_HasDiverged
end if
if used b3RecPlayer_IsAtEnd
	extrn b3RecPlayer_IsAtEnd
end if
if used b3RecPlayer_Restart
	extrn b3RecPlayer_Restart
end if
if used b3RecPlayer_SeekFrame
	extrn b3RecPlayer_SeekFrame
end if
if used b3RecPlayer_SetDebugShapeCallbacks
	extrn b3RecPlayer_SetDebugShapeCallbacks
end if
if used b3RecPlayer_SetKeyframePolicy
	extrn b3RecPlayer_SetKeyframePolicy
end if
if used b3RecPlayer_SetWorkerCount
	extrn b3RecPlayer_SetWorkerCount
end if
if used b3RecPlayer_StepFrame
	extrn b3RecPlayer_StepFrame
end if
if used b3Recording_GetData
	extrn b3Recording_GetData
end if
if used b3Recording_GetSize
	extrn b3Recording_GetSize
end if
if used b3RevoluteJoint_EnableLimit
	extrn b3RevoluteJoint_EnableLimit
end if
if used b3RevoluteJoint_EnableMotor
	extrn b3RevoluteJoint_EnableMotor
end if
if used b3RevoluteJoint_EnableSpring
	extrn b3RevoluteJoint_EnableSpring
end if
if used b3RevoluteJoint_GetAngle
	extrn b3RevoluteJoint_GetAngle
end if
if used b3RevoluteJoint_GetLowerLimit
	extrn b3RevoluteJoint_GetLowerLimit
end if
if used b3RevoluteJoint_GetMaxMotorTorque
	extrn b3RevoluteJoint_GetMaxMotorTorque
end if
if used b3RevoluteJoint_GetMotorSpeed
	extrn b3RevoluteJoint_GetMotorSpeed
end if
if used b3RevoluteJoint_GetMotorTorque
	extrn b3RevoluteJoint_GetMotorTorque
end if
if used b3RevoluteJoint_GetSpringDampingRatio
	extrn b3RevoluteJoint_GetSpringDampingRatio
end if
if used b3RevoluteJoint_GetSpringHertz
	extrn b3RevoluteJoint_GetSpringHertz
end if
if used b3RevoluteJoint_GetTargetAngle
	extrn b3RevoluteJoint_GetTargetAngle
end if
if used b3RevoluteJoint_GetUpperLimit
	extrn b3RevoluteJoint_GetUpperLimit
end if
if used b3RevoluteJoint_IsLimitEnabled
	extrn b3RevoluteJoint_IsLimitEnabled
end if
if used b3RevoluteJoint_IsMotorEnabled
	extrn b3RevoluteJoint_IsMotorEnabled
end if
if used b3RevoluteJoint_IsSpringEnabled
	extrn b3RevoluteJoint_IsSpringEnabled
end if
if used b3RevoluteJoint_SetLimits
	extrn b3RevoluteJoint_SetLimits
end if
if used b3RevoluteJoint_SetMaxMotorTorque
	extrn b3RevoluteJoint_SetMaxMotorTorque
end if
if used b3RevoluteJoint_SetMotorSpeed
	extrn b3RevoluteJoint_SetMotorSpeed
end if
if used b3RevoluteJoint_SetSpringDampingRatio
	extrn b3RevoluteJoint_SetSpringDampingRatio
end if
if used b3RevoluteJoint_SetSpringHertz
	extrn b3RevoluteJoint_SetSpringHertz
end if
if used b3RevoluteJoint_SetTargetAngle
	extrn b3RevoluteJoint_SetTargetAngle
end if
if used b3SaveRecordingToFile
	extrn b3SaveRecordingToFile
end if
if used b3ScaleBox
	extrn b3ScaleBox
end if
if used b3SegmentDistance
	extrn b3SegmentDistance
end if
if used b3SetAllocator
	extrn b3SetAllocator
end if
if used b3SetAssertFcn
	extrn b3SetAssertFcn
end if
if used b3SetLengthUnitsPerMeter
	extrn b3SetLengthUnitsPerMeter
end if
if used b3SetLogFcn
	extrn b3SetLogFcn
end if
if used b3SetStallThreshold
	extrn b3SetStallThreshold
end if
if used b3ShapeCast
	extrn b3ShapeCast
end if
if used b3ShapeCastCapsule
	extrn b3ShapeCastCapsule
end if
if used b3ShapeCastCompound
	extrn b3ShapeCastCompound
end if
if used b3ShapeCastHeightField
	extrn b3ShapeCastHeightField
end if
if used b3ShapeCastHull
	extrn b3ShapeCastHull
end if
if used b3ShapeCastMesh
	extrn b3ShapeCastMesh
end if
if used b3ShapeCastSphere
	extrn b3ShapeCastSphere
end if
if used b3ShapeDistance
	extrn b3ShapeDistance
end if
if used b3Shape_ApplyWind
	extrn b3Shape_ApplyWind
end if
if used b3Shape_AreContactEventsEnabled
	extrn b3Shape_AreContactEventsEnabled
end if
if used b3Shape_AreHitEventsEnabled
	extrn b3Shape_AreHitEventsEnabled
end if
if used b3Shape_ArePreSolveEventsEnabled
	extrn b3Shape_ArePreSolveEventsEnabled
end if
if used b3Shape_AreSensorEventsEnabled
	extrn b3Shape_AreSensorEventsEnabled
end if
if used b3Shape_ComputeMassData
	extrn b3Shape_ComputeMassData
end if
if used b3Shape_EnableContactEvents
	extrn b3Shape_EnableContactEvents
end if
if used b3Shape_EnableHitEvents
	extrn b3Shape_EnableHitEvents
end if
if used b3Shape_EnablePreSolveEvents
	extrn b3Shape_EnablePreSolveEvents
end if
if used b3Shape_EnableSensorEvents
	extrn b3Shape_EnableSensorEvents
end if
if used b3Shape_GetAABB
	extrn b3Shape_GetAABB
end if
if used b3Shape_GetBody
	extrn b3Shape_GetBody
end if
if used b3Shape_GetCapsule
	extrn b3Shape_GetCapsule
end if
if used b3Shape_GetClosestPoint
	extrn b3Shape_GetClosestPoint
end if
if used b3Shape_GetContactCapacity
	extrn b3Shape_GetContactCapacity
end if
if used b3Shape_GetContactData
	extrn b3Shape_GetContactData
end if
if used b3Shape_GetDensity
	extrn b3Shape_GetDensity
end if
if used b3Shape_GetFilter
	extrn b3Shape_GetFilter
end if
if used b3Shape_GetFriction
	extrn b3Shape_GetFriction
end if
if used b3Shape_GetHeightField
	extrn b3Shape_GetHeightField
end if
if used b3Shape_GetHull
	extrn b3Shape_GetHull
end if
if used b3Shape_GetMesh
	extrn b3Shape_GetMesh
end if
if used b3Shape_GetMeshMaterialCount
	extrn b3Shape_GetMeshMaterialCount
end if
if used b3Shape_GetMeshSurfaceMaterial
	extrn b3Shape_GetMeshSurfaceMaterial
end if
if used b3Shape_GetRestitution
	extrn b3Shape_GetRestitution
end if
if used b3Shape_GetSensorCapacity
	extrn b3Shape_GetSensorCapacity
end if
if used b3Shape_GetSensorData
	extrn b3Shape_GetSensorData
end if
if used b3Shape_GetSphere
	extrn b3Shape_GetSphere
end if
if used b3Shape_GetSurfaceMaterial
	extrn b3Shape_GetSurfaceMaterial
end if
if used b3Shape_GetType
	extrn b3Shape_GetType
end if
if used b3Shape_GetUserData
	extrn b3Shape_GetUserData
end if
if used b3Shape_GetWorld
	extrn b3Shape_GetWorld
end if
if used b3Shape_IsSensor
	extrn b3Shape_IsSensor
end if
if used b3Shape_IsValid
	extrn b3Shape_IsValid
end if
if used b3Shape_RayCast
	extrn b3Shape_RayCast
end if
if used b3Shape_SetCapsule
	extrn b3Shape_SetCapsule
end if
if used b3Shape_SetDensity
	extrn b3Shape_SetDensity
end if
if used b3Shape_SetFilter
	extrn b3Shape_SetFilter
end if
if used b3Shape_SetFriction
	extrn b3Shape_SetFriction
end if
if used b3Shape_SetHull
	extrn b3Shape_SetHull
end if
if used b3Shape_SetMesh
	extrn b3Shape_SetMesh
end if
if used b3Shape_SetMeshMaterial
	extrn b3Shape_SetMeshMaterial
end if
if used b3Shape_SetRestitution
	extrn b3Shape_SetRestitution
end if
if used b3Shape_SetSphere
	extrn b3Shape_SetSphere
end if
if used b3Shape_SetSurfaceMaterial
	extrn b3Shape_SetSurfaceMaterial
end if
if used b3Shape_SetUserData
	extrn b3Shape_SetUserData
end if
if used b3Sleep
	extrn b3Sleep
end if
if used b3SolvePlanes
	extrn b3SolvePlanes
end if
if used b3SphericalJoint_EnableConeLimit
	extrn b3SphericalJoint_EnableConeLimit
end if
if used b3SphericalJoint_EnableMotor
	extrn b3SphericalJoint_EnableMotor
end if
if used b3SphericalJoint_EnableSpring
	extrn b3SphericalJoint_EnableSpring
end if
if used b3SphericalJoint_EnableTwistLimit
	extrn b3SphericalJoint_EnableTwistLimit
end if
if used b3SphericalJoint_GetConeAngle
	extrn b3SphericalJoint_GetConeAngle
end if
if used b3SphericalJoint_GetConeLimit
	extrn b3SphericalJoint_GetConeLimit
end if
if used b3SphericalJoint_GetLowerTwistLimit
	extrn b3SphericalJoint_GetLowerTwistLimit
end if
if used b3SphericalJoint_GetMaxMotorTorque
	extrn b3SphericalJoint_GetMaxMotorTorque
end if
if used b3SphericalJoint_GetMotorTorque
	extrn b3SphericalJoint_GetMotorTorque
end if
if used b3SphericalJoint_GetMotorVelocity
	extrn b3SphericalJoint_GetMotorVelocity
end if
if used b3SphericalJoint_GetSpringDampingRatio
	extrn b3SphericalJoint_GetSpringDampingRatio
end if
if used b3SphericalJoint_GetSpringHertz
	extrn b3SphericalJoint_GetSpringHertz
end if
if used b3SphericalJoint_GetTargetRotation
	extrn b3SphericalJoint_GetTargetRotation
end if
if used b3SphericalJoint_GetTwistAngle
	extrn b3SphericalJoint_GetTwistAngle
end if
if used b3SphericalJoint_GetUpperTwistLimit
	extrn b3SphericalJoint_GetUpperTwistLimit
end if
if used b3SphericalJoint_IsConeLimitEnabled
	extrn b3SphericalJoint_IsConeLimitEnabled
end if
if used b3SphericalJoint_IsMotorEnabled
	extrn b3SphericalJoint_IsMotorEnabled
end if
if used b3SphericalJoint_IsSpringEnabled
	extrn b3SphericalJoint_IsSpringEnabled
end if
if used b3SphericalJoint_IsTwistLimitEnabled
	extrn b3SphericalJoint_IsTwistLimitEnabled
end if
if used b3SphericalJoint_SetConeLimit
	extrn b3SphericalJoint_SetConeLimit
end if
if used b3SphericalJoint_SetMaxMotorTorque
	extrn b3SphericalJoint_SetMaxMotorTorque
end if
if used b3SphericalJoint_SetMotorVelocity
	extrn b3SphericalJoint_SetMotorVelocity
end if
if used b3SphericalJoint_SetSpringDampingRatio
	extrn b3SphericalJoint_SetSpringDampingRatio
end if
if used b3SphericalJoint_SetSpringHertz
	extrn b3SphericalJoint_SetSpringHertz
end if
if used b3SphericalJoint_SetTargetRotation
	extrn b3SphericalJoint_SetTargetRotation
end if
if used b3SphericalJoint_SetTwistLimits
	extrn b3SphericalJoint_SetTwistLimits
end if
if used b3Steiner
	extrn b3Steiner
end if
if used b3TimeOfImpact
	extrn b3TimeOfImpact
end if
if used b3ValidateReplay
	extrn b3ValidateReplay
end if
if used b3WeldJoint_GetAngularDampingRatio
	extrn b3WeldJoint_GetAngularDampingRatio
end if
if used b3WeldJoint_GetAngularHertz
	extrn b3WeldJoint_GetAngularHertz
end if
if used b3WeldJoint_GetLinearDampingRatio
	extrn b3WeldJoint_GetLinearDampingRatio
end if
if used b3WeldJoint_GetLinearHertz
	extrn b3WeldJoint_GetLinearHertz
end if
if used b3WeldJoint_SetAngularDampingRatio
	extrn b3WeldJoint_SetAngularDampingRatio
end if
if used b3WeldJoint_SetAngularHertz
	extrn b3WeldJoint_SetAngularHertz
end if
if used b3WeldJoint_SetLinearDampingRatio
	extrn b3WeldJoint_SetLinearDampingRatio
end if
if used b3WeldJoint_SetLinearHertz
	extrn b3WeldJoint_SetLinearHertz
end if
if used b3WheelJoint_EnableSpinMotor
	extrn b3WheelJoint_EnableSpinMotor
end if
if used b3WheelJoint_EnableSteering
	extrn b3WheelJoint_EnableSteering
end if
if used b3WheelJoint_EnableSteeringLimit
	extrn b3WheelJoint_EnableSteeringLimit
end if
if used b3WheelJoint_EnableSuspension
	extrn b3WheelJoint_EnableSuspension
end if
if used b3WheelJoint_EnableSuspensionLimit
	extrn b3WheelJoint_EnableSuspensionLimit
end if
if used b3WheelJoint_GetLowerSteeringLimit
	extrn b3WheelJoint_GetLowerSteeringLimit
end if
if used b3WheelJoint_GetLowerSuspensionLimit
	extrn b3WheelJoint_GetLowerSuspensionLimit
end if
if used b3WheelJoint_GetMaxSpinTorque
	extrn b3WheelJoint_GetMaxSpinTorque
end if
if used b3WheelJoint_GetMaxSteeringTorque
	extrn b3WheelJoint_GetMaxSteeringTorque
end if
if used b3WheelJoint_GetSpinMotorSpeed
	extrn b3WheelJoint_GetSpinMotorSpeed
end if
if used b3WheelJoint_GetSpinSpeed
	extrn b3WheelJoint_GetSpinSpeed
end if
if used b3WheelJoint_GetSpinTorque
	extrn b3WheelJoint_GetSpinTorque
end if
if used b3WheelJoint_GetSteeringAngle
	extrn b3WheelJoint_GetSteeringAngle
end if
if used b3WheelJoint_GetSteeringDampingRatio
	extrn b3WheelJoint_GetSteeringDampingRatio
end if
if used b3WheelJoint_GetSteeringHertz
	extrn b3WheelJoint_GetSteeringHertz
end if
if used b3WheelJoint_GetSteeringTorque
	extrn b3WheelJoint_GetSteeringTorque
end if
if used b3WheelJoint_GetSuspensionDampingRatio
	extrn b3WheelJoint_GetSuspensionDampingRatio
end if
if used b3WheelJoint_GetSuspensionHertz
	extrn b3WheelJoint_GetSuspensionHertz
end if
if used b3WheelJoint_GetTargetSteeringAngle
	extrn b3WheelJoint_GetTargetSteeringAngle
end if
if used b3WheelJoint_GetUpperSteeringLimit
	extrn b3WheelJoint_GetUpperSteeringLimit
end if
if used b3WheelJoint_GetUpperSuspensionLimit
	extrn b3WheelJoint_GetUpperSuspensionLimit
end if
if used b3WheelJoint_IsSpinMotorEnabled
	extrn b3WheelJoint_IsSpinMotorEnabled
end if
if used b3WheelJoint_IsSteeringEnabled
	extrn b3WheelJoint_IsSteeringEnabled
end if
if used b3WheelJoint_IsSteeringLimitEnabled
	extrn b3WheelJoint_IsSteeringLimitEnabled
end if
if used b3WheelJoint_IsSuspensionEnabled
	extrn b3WheelJoint_IsSuspensionEnabled
end if
if used b3WheelJoint_IsSuspensionLimitEnabled
	extrn b3WheelJoint_IsSuspensionLimitEnabled
end if
if used b3WheelJoint_SetMaxSpinTorque
	extrn b3WheelJoint_SetMaxSpinTorque
end if
if used b3WheelJoint_SetMaxSteeringTorque
	extrn b3WheelJoint_SetMaxSteeringTorque
end if
if used b3WheelJoint_SetSpinMotorSpeed
	extrn b3WheelJoint_SetSpinMotorSpeed
end if
if used b3WheelJoint_SetSteeringDampingRatio
	extrn b3WheelJoint_SetSteeringDampingRatio
end if
if used b3WheelJoint_SetSteeringHertz
	extrn b3WheelJoint_SetSteeringHertz
end if
if used b3WheelJoint_SetSteeringLimits
	extrn b3WheelJoint_SetSteeringLimits
end if
if used b3WheelJoint_SetSuspensionDampingRatio
	extrn b3WheelJoint_SetSuspensionDampingRatio
end if
if used b3WheelJoint_SetSuspensionHertz
	extrn b3WheelJoint_SetSuspensionHertz
end if
if used b3WheelJoint_SetSuspensionLimits
	extrn b3WheelJoint_SetSuspensionLimits
end if
if used b3WheelJoint_SetTargetSteeringAngle
	extrn b3WheelJoint_SetTargetSteeringAngle
end if
if used b3World_CastMover
	extrn b3World_CastMover
end if
if used b3World_CastRay
	extrn b3World_CastRay
end if
if used b3World_CastRayClosest
	extrn b3World_CastRayClosest
end if
if used b3World_CastShape
	extrn b3World_CastShape
end if
if used b3World_CollideMover
	extrn b3World_CollideMover
end if
if used b3World_Draw
	extrn b3World_Draw
end if
if used b3World_Dump
	extrn b3World_Dump
end if
if used b3World_DumpAwake
	extrn b3World_DumpAwake
end if
if used b3World_DumpMemoryStats
	extrn b3World_DumpMemoryStats
end if
if used b3World_DumpShapeBounds
	extrn b3World_DumpShapeBounds
end if
if used b3World_EnableContinuous
	extrn b3World_EnableContinuous
end if
if used b3World_EnableSleeping
	extrn b3World_EnableSleeping
end if
if used b3World_EnableSpeculative
	extrn b3World_EnableSpeculative
end if
if used b3World_EnableWarmStarting
	extrn b3World_EnableWarmStarting
end if
if used b3World_Explode
	extrn b3World_Explode
end if
if used b3World_GetAwakeBodyCount
	extrn b3World_GetAwakeBodyCount
end if
if used b3World_GetBodyEvents
	extrn b3World_GetBodyEvents
end if
if used b3World_GetBounds
	extrn b3World_GetBounds
end if
if used b3World_GetContactEvents
	extrn b3World_GetContactEvents
end if
if used b3World_GetContactRecycleDistance
	extrn b3World_GetContactRecycleDistance
end if
if used b3World_GetCounters
	extrn b3World_GetCounters
end if
if used b3World_GetGravity
	extrn b3World_GetGravity
end if
if used b3World_GetHitEventThreshold
	extrn b3World_GetHitEventThreshold
end if
if used b3World_GetJointEvents
	extrn b3World_GetJointEvents
end if
if used b3World_GetMaxCapacity
	extrn b3World_GetMaxCapacity
end if
if used b3World_GetMaximumLinearSpeed
	extrn b3World_GetMaximumLinearSpeed
end if
if used b3World_GetProfile
	extrn b3World_GetProfile
end if
if used b3World_GetRestitutionThreshold
	extrn b3World_GetRestitutionThreshold
end if
if used b3World_GetSensorEvents
	extrn b3World_GetSensorEvents
end if
if used b3World_GetUserData
	extrn b3World_GetUserData
end if
if used b3World_GetWorkerCount
	extrn b3World_GetWorkerCount
end if
if used b3World_IsContinuousEnabled
	extrn b3World_IsContinuousEnabled
end if
if used b3World_IsSleepingEnabled
	extrn b3World_IsSleepingEnabled
end if
if used b3World_IsValid
	extrn b3World_IsValid
end if
if used b3World_IsWarmStartingEnabled
	extrn b3World_IsWarmStartingEnabled
end if
if used b3World_OverlapAABB
	extrn b3World_OverlapAABB
end if
if used b3World_OverlapShape
	extrn b3World_OverlapShape
end if
if used b3World_RebuildStaticTree
	extrn b3World_RebuildStaticTree
end if
if used b3World_SetContactRecycleDistance
	extrn b3World_SetContactRecycleDistance
end if
if used b3World_SetContactTuning
	extrn b3World_SetContactTuning
end if
if used b3World_SetCustomFilterCallback
	extrn b3World_SetCustomFilterCallback
end if
if used b3World_SetFrictionCallback
	extrn b3World_SetFrictionCallback
end if
if used b3World_SetGravity
	extrn b3World_SetGravity
end if
if used b3World_SetHitEventThreshold
	extrn b3World_SetHitEventThreshold
end if
if used b3World_SetMaximumLinearSpeed
	extrn b3World_SetMaximumLinearSpeed
end if
if used b3World_SetPreSolveCallback
	extrn b3World_SetPreSolveCallback
end if
if used b3World_SetRestitutionCallback
	extrn b3World_SetRestitutionCallback
end if
if used b3World_SetRestitutionThreshold
	extrn b3World_SetRestitutionThreshold
end if
if used b3World_SetUserData
	extrn b3World_SetUserData
end if
if used b3World_SetWorkerCount
	extrn b3World_SetWorkerCount
end if
if used b3World_StartRecording
	extrn b3World_StartRecording
end if
if used b3World_Step
	extrn b3World_Step
end if
if used b3World_StopRecording
	extrn b3World_StopRecording
end if
if used b3WriteBinaryFile
	extrn b3WriteBinaryFile
end if
if used b3Yield
	extrn b3Yield
end if
