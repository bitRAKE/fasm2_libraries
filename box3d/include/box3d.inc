; Box3D C API for fasm2
; SPDX-FileCopyrightText: 2026 Erin Catto (Box3D)
; SPDX-License-Identifier: MIT
;
; Mirrors the public C interface in include/box3d for the default build:
; single precision (no BOX3D_DOUBLE_PRECISION), MSVC x64 layout rules.
; b3Pos/b3WorldTransform are separate structs here but have the same layout
; as b3Vec3/b3Transform, exactly like the C typedefs in single precision mode.
;
; Field mapping: float=dd, double=dq, int/int32_t/uint32_t/enum=dd,
; uint64_t=dq, pointers=dq, bool=db, uint16_t=dw, uint8_t=db.
; Explicit `rb` fields reproduce the C compiler's alignment padding.
; Layouts are checked against the C compiler by bindings/fasm2/test.
;
; Win x64 ABI notes for callers:
; - Structs of 1, 2, 4, or 8 bytes (b3WorldId, b3BodyId, b3ShapeId,
;   b3JointId, ...) pass and return by value in a GP register.
; - Larger structs (b3Vec3, b3Version, b3ContactId, ...) are passed by
;   pointer to a caller-owned copy and returned through a hidden pointer
;   argument that takes the first parameter slot (RCX).

; struct.inc marks itself with `define struct? struct?`; probe that symbolic
; with irpv (which does not substitute) and skip the include when another
; file, like win64a.inc, already loaded it
B3.StructLoaded = 0
irpv value, struct?
	B3.StructLoaded = 1
end irpv
if ~ B3.StructLoaded
	include 'macro/struct.inc'
end if

; ---------------------------------------------------------------------------
; constants (base.h, constants.h, math_functions.h, types.h)

B3_NULL_INDEX                        = -1
B3_HASH_INIT                         = 5381

B3_MAX_WORKERS                       = 32
B3_MAX_TASKS                         = 256
B3_GRAPH_COLOR_COUNT                 = 24
B3_CONTACT_MANIFOLD_COUNT_BUCKETS    = 8
B3_MAX_WORLDS                        = 128
B3_BODY_NAME_LENGTH                  = 18
B3_SHAPE_NAME_LENGTH                 = 18
B3_MAX_MANIFOLD_POINTS               = 4
B3_MAX_SHAPE_CAST_POINTS             = 64
B3_SHAPE_POWER                       = 22
B3_CHILD_POWER                       = 64 - 2*B3_SHAPE_POWER
B3_MAX_SHAPES                        = 1 shl B3_SHAPE_POWER
B3_MAX_CHILD_SHAPES                  = 1 shl B3_CHILD_POWER

B3_DEFAULT_CATEGORY_BITS             = 0xFFFFFFFFFFFFFFFF
B3_DEFAULT_MASK_BITS                 = 0xFFFFFFFFFFFFFFFF

B3_DYNAMIC_TREE_VERSION              = 0x93EDAF889FD30B4A
B3_HULL_VERSION                      = 0x9D4716CE3793900E
B3_MESH_VERSION                      = 0xABD11AB62A6E886D
B3_HEIGHT_FIELD_VERSION              = 0x8B18CBD138A6BC84
B3_COMPOUND_VERSION                  = 0x830778DB07086EB4 xor B3_DYNAMIC_TREE_VERSION xor B3_MESH_VERSION xor B3_HULL_VERSION

B3_HEIGHT_FIELD_HOLE                 = 0xFF
B3_MAX_COMPOUND_MESH_MATERIALS       = 4

; floating point constants (not machine-verified, values from the headers)
B3_PI                                = 3.14159265359
B3_DEG_TO_RAD                        = 0.01745329251
B3_RAD_TO_DEG                        = 57.2957795131
B3_MIN_SCALE                         = 0.01
B3_AABB_MARGIN_FRACTION              = 0.125
B3_TIME_TO_SLEEP                     = 0.5
B3_CONTACT_RECYCLE_ANGULAR_DISTANCE  = 0.99240388

; ---------------------------------------------------------------------------
; enumerations

; b3BodyType
b3_staticBody                        = 0
b3_kinematicBody                     = 1
b3_dynamicBody                       = 2
b3_bodyTypeCount                     = 3

; b3ShapeType
b3_capsuleShape                      = 0
b3_compoundShape                     = 1
b3_heightShape                       = 2
b3_hullShape                         = 3
b3_meshShape                         = 4
b3_sphereShape                       = 5
b3_shapeTypeCount                    = 6

; b3JointType
b3_parallelJoint                     = 0
b3_distanceJoint                     = 1
b3_filterJoint                       = 2
b3_motorJoint                        = 3
b3_prismaticJoint                    = 4
b3_revoluteJoint                     = 5
b3_sphericalJoint                    = 6
b3_weldJoint                         = 7
b3_wheelJoint                        = 8

; b3TOIState
b3_toiStateUnknown                   = 0
b3_toiStateFailed                    = 1
b3_toiStateOverlapped                = 2
b3_toiStateHit                       = 3
b3_toiStateSeparated                 = 4

; b3TreeNodeFlags
b3_allocatedNode                     = 0x0001
b3_enlargedNode                      = 0x0002
b3_leafNode                          = 0x0004

; b3MeshEdgeFlags
b3_concaveEdge1                      = 0x01
b3_concaveEdge2                      = 0x02
b3_concaveEdge3                      = 0x04
b3_inverseConcaveEdge1               = 0x10
b3_inverseConcaveEdge2               = 0x20
b3_inverseConcaveEdge3               = 0x40
b3_allConcaveEdges                   = b3_concaveEdge1 or b3_concaveEdge2 or b3_concaveEdge3
b3_flatEdge1                         = b3_concaveEdge1 or b3_inverseConcaveEdge1
b3_flatEdge2                         = b3_concaveEdge2 or b3_inverseConcaveEdge2
b3_flatEdge3                         = b3_concaveEdge3 or b3_inverseConcaveEdge3
b3_allFlatEdges                      = b3_flatEdge1 or b3_flatEdge2 or b3_flatEdge3

; b3SeparatingFeature
b3_invalidAxis                       = 0
b3_backsideAxis                      = 1
b3_faceAxisA                         = 2
b3_faceAxisB                         = 3
b3_edgePairAxis                      = 4
b3_closestPointsAxis                 = 5
b3_manualFaceAxisA                   = 6
b3_manualFaceAxisB                   = 7
b3_manualEdgePairAxis                = 8

; b3TriangleFeature
b3_featureNone                       = 0
b3_featureTriangleFace               = 1
b3_featureHullFace                   = 2
b3_featureEdge1                      = 3
b3_featureEdge2                      = 4
b3_featureEdge3                      = 5
b3_featureVertex1                    = 6
b3_featureVertex2                    = 7
b3_featureVertex3                    = 8

; b3DebugMaterial
b3_debugMaterialDefault              = 0
b3_debugMaterialMatte                = 1
b3_debugMaterialSoft                 = 2
b3_debugMaterialDead                 = 3
b3_debugMaterialGlossy               = 4
b3_debugMaterialMetallic             = 5

; b3RecQueryType
b3_recQueryOverlapAABB               = 0
b3_recQueryOverlapShape              = 1
b3_recQueryCastRay                   = 2
b3_recQueryCastShape                 = 3
b3_recQueryCastRayClosest            = 4
b3_recQueryCastMover                 = 5
b3_recQueryCollideMover              = 6

; b3HexColor
b3_colorAliceBlue                    = 0xF0F8FF
b3_colorAntiqueWhite                 = 0xFAEBD7
b3_colorAqua                         = 0x00FFFF
b3_colorAquamarine                   = 0x7FFFD4
b3_colorAzure                        = 0xF0FFFF
b3_colorBeige                        = 0xF5F5DC
b3_colorBisque                       = 0xFFE4C4
b3_colorBlack                        = 0x000000
b3_colorBlanchedAlmond               = 0xFFEBCD
b3_colorBlue                         = 0x0000FF
b3_colorBlueViolet                   = 0x8A2BE2
b3_colorBrown                        = 0xA52A2A
b3_colorBurlywood                    = 0xDEB887
b3_colorCadetBlue                    = 0x5F9EA0
b3_colorChartreuse                   = 0x7FFF00
b3_colorChocolate                    = 0xD2691E
b3_colorCoral                        = 0xFF7F50
b3_colorCornflowerBlue               = 0x6495ED
b3_colorCornsilk                     = 0xFFF8DC
b3_colorCrimson                      = 0xDC143C
b3_colorCyan                         = 0x00FFFF
b3_colorDarkBlue                     = 0x00008B
b3_colorDarkCyan                     = 0x008B8B
b3_colorDarkGoldenRod                = 0xB8860B
b3_colorDarkGray                     = 0xA9A9A9
b3_colorDarkGreen                    = 0x006400
b3_colorDarkKhaki                    = 0xBDB76B
b3_colorDarkMagenta                  = 0x8B008B
b3_colorDarkOliveGreen               = 0x556B2F
b3_colorDarkOrange                   = 0xFF8C00
b3_colorDarkOrchid                   = 0x9932CC
b3_colorDarkRed                      = 0x8B0000
b3_colorDarkSalmon                   = 0xE9967A
b3_colorDarkSeaGreen                 = 0x8FBC8F
b3_colorDarkSlateBlue                = 0x483D8B
b3_colorDarkSlateGray                = 0x2F4F4F
b3_colorDarkTurquoise                = 0x00CED1
b3_colorDarkViolet                   = 0x9400D3
b3_colorDeepPink                     = 0xFF1493
b3_colorDeepSkyBlue                  = 0x00BFFF
b3_colorDimGray                      = 0x696969
b3_colorDodgerBlue                   = 0x1E90FF
b3_colorFireBrick                    = 0xB22222
b3_colorFloralWhite                  = 0xFFFAF0
b3_colorForestGreen                  = 0x228B22
b3_colorFuchsia                      = 0xFF00FF
b3_colorGainsboro                    = 0xDCDCDC
b3_colorGhostWhite                   = 0xF8F8FF
b3_colorGold                         = 0xFFD700
b3_colorGoldenRod                    = 0xDAA520
b3_colorGray                         = 0x808080
b3_colorGreen                        = 0x008000
b3_colorGreenYellow                  = 0xADFF2F
b3_colorHoneyDew                     = 0xF0FFF0
b3_colorHotPink                      = 0xFF69B4
b3_colorIndianRed                    = 0xCD5C5C
b3_colorIndigo                       = 0x4B0082
b3_colorIvory                        = 0xFFFFF0
b3_colorKhaki                        = 0xF0E68C
b3_colorLavender                     = 0xE6E6FA
b3_colorLavenderBlush                = 0xFFF0F5
b3_colorLawnGreen                    = 0x7CFC00
b3_colorLemonChiffon                 = 0xFFFACD
b3_colorLightBlue                    = 0xADD8E6
b3_colorLightCoral                   = 0xF08080
b3_colorLightCyan                    = 0xE0FFFF
b3_colorLightGoldenRodYellow         = 0xFAFAD2
b3_colorLightGray                    = 0xD3D3D3
b3_colorLightGreen                   = 0x90EE90
b3_colorLightPink                    = 0xFFB6C1
b3_colorLightSalmon                  = 0xFFA07A
b3_colorLightSeaGreen                = 0x20B2AA
b3_colorLightSkyBlue                 = 0x87CEFA
b3_colorLightSlateGray               = 0x778899
b3_colorLightSteelBlue               = 0xB0C4DE
b3_colorLightYellow                  = 0xFFFFE0
b3_colorLime                         = 0x00FF00
b3_colorLimeGreen                    = 0x32CD32
b3_colorLinen                        = 0xFAF0E6
b3_colorMagenta                      = 0xFF00FF
b3_colorMaroon                       = 0x800000
b3_colorMediumAquaMarine             = 0x66CDAA
b3_colorMediumBlue                   = 0x0000CD
b3_colorMediumOrchid                 = 0xBA55D3
b3_colorMediumPurple                 = 0x9370DB
b3_colorMediumSeaGreen               = 0x3CB371
b3_colorMediumSlateBlue              = 0x7B68EE
b3_colorMediumSpringGreen            = 0x00FA9A
b3_colorMediumTurquoise              = 0x48D1CC
b3_colorMediumVioletRed              = 0xC71585
b3_colorMidnightBlue                 = 0x191970
b3_colorMintCream                    = 0xF5FFFA
b3_colorMistyRose                    = 0xFFE4E1
b3_colorMoccasin                     = 0xFFE4B5
b3_colorNavajoWhite                  = 0xFFDEAD
b3_colorNavy                         = 0x000080
b3_colorOldLace                      = 0xFDF5E6
b3_colorOlive                        = 0x808000
b3_colorOliveDrab                    = 0x6B8E23
b3_colorOrange                       = 0xFFA500
b3_colorOrangeRed                    = 0xFF4500
b3_colorOrchid                       = 0xDA70D6
b3_colorPaleGoldenRod                = 0xEEE8AA
b3_colorPaleGreen                    = 0x98FB98
b3_colorPaleTurquoise                = 0xAFEEEE
b3_colorPaleVioletRed                = 0xDB7093
b3_colorPapayaWhip                   = 0xFFEFD5
b3_colorPeachPuff                    = 0xFFDAB9
b3_colorPeru                         = 0xCD853F
b3_colorPink                         = 0xFFC0CB
b3_colorPlum                         = 0xDDA0DD
b3_colorPowderBlue                   = 0xB0E0E6
b3_colorPurple                       = 0x800080
b3_colorRebeccaPurple                = 0x663399
b3_colorRed                          = 0xFF0000
b3_colorRosyBrown                    = 0xBC8F8F
b3_colorRoyalBlue                    = 0x4169E1
b3_colorSaddleBrown                  = 0x8B4513
b3_colorSalmon                       = 0xFA8072
b3_colorSandyBrown                   = 0xF4A460
b3_colorSeaGreen                     = 0x2E8B57
b3_colorSeaShell                     = 0xFFF5EE
b3_colorSienna                       = 0xA0522D
b3_colorSilver                       = 0xC0C0C0
b3_colorSkyBlue                      = 0x87CEEB
b3_colorSlateBlue                    = 0x6A5ACD
b3_colorSlateGray                    = 0x708090
b3_colorSnow                         = 0xFFFAFA
b3_colorSpringGreen                  = 0x00FF7F
b3_colorSteelBlue                    = 0x4682B4
b3_colorTan                          = 0xD2B48C
b3_colorTeal                         = 0x008080
b3_colorThistle                      = 0xD8BFD8
b3_colorTomato                       = 0xFF6347
b3_colorTurquoise                    = 0x40E0D0
b3_colorViolet                       = 0xEE82EE
b3_colorWheat                        = 0xF5DEB3
b3_colorWhite                        = 0xFFFFFF
b3_colorWhiteSmoke                   = 0xF5F5F5
b3_colorYellow                       = 0xFFFF00
b3_colorYellowGreen                  = 0x9ACD32
b3_colorBox2DRed                     = 0xDC3132
b3_colorBox2DBlue                    = 0x30AEBF
b3_colorBox2DGreen                   = 0x8CC924
b3_colorBox2DYellow                  = 0xFFEE8C

; ---------------------------------------------------------------------------
; base.h

struct b3Version
  major    dd ?
  minor    dd ?
  revision dd ?
ends

; ---------------------------------------------------------------------------
; id.h

struct b3WorldId
  index1     dw ?
  generation dw ?
ends

struct b3BodyId
  index1     dd ?
  world0     dw ?
  generation dw ?
ends

struct b3ShapeId
  index1     dd ?
  world0     dw ?
  generation dw ?
ends

struct b3JointId
  index1     dd ?
  world0     dw ?
  generation dw ?
ends

struct b3ContactId
  index1     dd ?
  world0     dw ?
  padding    dw ?
  generation dd ?
ends

; ---------------------------------------------------------------------------
; math_functions.h

struct b3Vec2
  x dd ?
  y dd ?
ends

struct b3Vec3
  x dd ?
  y dd ?
  z dd ?
ends

struct b3CosSin
  cosine dd ?
  sine   dd ?
ends

struct b3Quat
  v b3Vec3
  s dd ?
ends

struct b3Transform
  p b3Vec3
  q b3Quat
ends

; single precision typedef of b3Vec3
struct b3Pos
  x dd ?
  y dd ?
  z dd ?
ends

; single precision typedef of b3Transform
struct b3WorldTransform
  p b3Pos
  q b3Quat
ends

struct b3Matrix3
  cx b3Vec3
  cy b3Vec3
  cz b3Vec3
ends

struct b3AABB
  lowerBound b3Vec3
  upperBound b3Vec3
ends

struct b3Plane
  normal b3Vec3
  offset dd ?
ends

struct b3SegmentDistanceResult
  point1    b3Vec3
  fraction1 dd ?
  point2    b3Vec3
  fraction2 dd ?
ends

; ---------------------------------------------------------------------------
; types.h

struct b3Capacity
  staticShapeCount  dd ?
  dynamicShapeCount dd ?
  staticBodyCount   dd ?
  dynamicBodyCount  dd ?
  contactCount      dd ?
ends

struct b3WorldDef
  gravity               b3Vec3
  restitutionThreshold  dd ?
  hitEventThreshold     dd ?
  contactHertz          dd ?
  contactDampingRatio   dd ?
  contactSpeed          dd ?
  maximumLinearSpeed    dd ?
                        rb 4
  frictionCallback      dq ?
  restitutionCallback   dq ?
  enableSleep           db ?
  enableContinuous      db ?
                        rb 2
  workerCount           dd ?
  enqueueTask           dq ?
  finishTask            dq ?
  userTaskContext       dq ?
  userData              dq ?
  createDebugShape      dq ?
  destroyDebugShape     dq ?
  userDebugShapeContext dq ?
  capacity              b3Capacity
  internalValue         dd ?
ends

struct b3MotionLocks
  linearX  db ?
  linearY  db ?
  linearZ  db ?
  angularX db ?
  angularY db ?
  angularZ db ?
ends

struct b3BodyDef
  type                   dd ?
  position               b3Pos
  rotation               b3Quat
  linearVelocity         b3Vec3
  angularVelocity        b3Vec3
  linearDamping          dd ?
  angularDamping         dd ?
  gravityScale           dd ?
  sleepThreshold         dd ?
  name                   dq ?
  userData               dq ?
  motionLocks            b3MotionLocks
  enableSleep            db ?
  isAwake                db ?
  isBullet               db ?
  isEnabled              db ?
  allowFastRotation      db ?
  enableContactRecycling db ?
  internalValue          dd ?
ends

struct b3Filter
  categoryBits dq ?
  maskBits     dq ?
  groupIndex   dd ?
               rb 4
ends

struct b3SurfaceMaterial
  friction          dd ?
  restitution       dd ?
  rollingResistance dd ?
  tangentVelocity   b3Vec3
  userMaterialId    dq ?
  customColor       dd ?
                    rb 4
ends

struct b3ShapeDef
  userData              dq ?
  materials             dq ?
  materialCount         dd ?
                        rb 4
  baseMaterial          b3SurfaceMaterial
  density               dd ?
  explosionScale        dd ?
  filter                b3Filter
  enableCustomFiltering db ?
  isSensor              db ?
  enableSensorEvents    db ?
  enableContactEvents   db ?
  enableHitEvents       db ?
  enablePreSolveEvents  db ?
  invokeContactCreation db ?
  updateBodyMass        db ?
  internalValue         dd ?
                        rb 4
ends

struct b3Profile
  step                dd ?
  pairs               dd ?
  collide             dd ?
  solve               dd ?
  solverSetup         dd ?
  constraints         dd ?
  prepareConstraints  dd ?
  integrateVelocities dd ?
  warmStart           dd ?
  solveImpulses       dd ?
  integratePositions  dd ?
  relaxImpulses       dd ?
  applyRestitution    dd ?
  storeImpulses       dd ?
  splitIslands        dd ?
  transforms          dd ?
  sensorHits          dd ?
  jointEvents         dd ?
  hitEvents           dd ?
  refit               dd ?
  bullets             dd ?
  sleepIslands        dd ?
  sensors             dd ?
ends

struct b3Counters
  bodyCount            dd ?
  shapeCount           dd ?
  contactCount         dd ?
  jointCount           dd ?
  islandCount          dd ?
  stackUsed            dd ?
  arenaCapacity        dd ?
  staticTreeHeight     dd ?
  treeHeight           dd ?
  satCallCount         dd ?
  satCacheHitCount     dd ?
  byteCount            dd ?
  taskCount            dd ?
  colorCounts          rd 24
  manifoldCounts       rd B3_CONTACT_MANIFOLD_COUNT_BUCKETS
  awakeContactCount    dd ?
  recycledContactCount dd ?
  distanceIterations   dd ?
  pushBackIterations   dd ?
  rootIterations       dd ?
ends

struct b3JointDef
  userData               dq ?
  bodyIdA                b3BodyId
  bodyIdB                b3BodyId
  localFrameA            b3Transform
  localFrameB            b3Transform
  forceThreshold         dd ?
  torqueThreshold        dd ?
  constraintHertz        dd ?
  constraintDampingRatio dd ?
  drawScale              dd ?
  collideConnected       db ?
                         rb 3
  internalValue          dd ?
                         rb 4
ends

struct b3DistanceJointDef
  base             b3JointDef
  length           dd ?
  enableSpring     db ?
                   rb 3
  lowerSpringForce dd ?
  upperSpringForce dd ?
  hertz            dd ?
  dampingRatio     dd ?
  enableLimit      db ?
                   rb 3
  minLength        dd ?
  maxLength        dd ?
  enableMotor      db ?
                   rb 3
  maxMotorForce    dd ?
  motorSpeed       dd ?
ends

struct b3MotorJointDef
  base                b3JointDef
  linearVelocity      b3Vec3
  maxVelocityForce    dd ?
  angularVelocity     b3Vec3
  maxVelocityTorque   dd ?
  linearHertz         dd ?
  linearDampingRatio  dd ?
  maxSpringForce      dd ?
  angularHertz        dd ?
  angularDampingRatio dd ?
  maxSpringTorque     dd ?
ends

struct b3FilterJointDef
  base b3JointDef
ends

struct b3ParallelJointDef
  base         b3JointDef
  hertz        dd ?
  dampingRatio dd ?
  maxTorque    dd ?
               rb 4
ends

struct b3PrismaticJointDef
  base              b3JointDef
  enableSpring      db ?
                    rb 3
  hertz             dd ?
  dampingRatio      dd ?
  targetTranslation dd ?
  enableLimit       db ?
                    rb 3
  lowerTranslation  dd ?
  upperTranslation  dd ?
  enableMotor       db ?
                    rb 3
  maxMotorForce     dd ?
  motorSpeed        dd ?
ends

struct b3RevoluteJointDef
  base           b3JointDef
  targetAngle    dd ?
  enableSpring   db ?
                 rb 3
  hertz          dd ?
  dampingRatio   dd ?
  enableLimit    db ?
                 rb 3
  lowerAngle     dd ?
  upperAngle     dd ?
  enableMotor    db ?
                 rb 3
  maxMotorTorque dd ?
  motorSpeed     dd ?
ends

struct b3SphericalJointDef
  base             b3JointDef
  enableSpring     db ?
                   rb 3
  hertz            dd ?
  dampingRatio     dd ?
  targetRotation   b3Quat
  enableConeLimit  db ?
                   rb 3
  coneAngle        dd ?
  enableTwistLimit db ?
                   rb 3
  lowerTwistAngle  dd ?
  upperTwistAngle  dd ?
  enableMotor      db ?
                   rb 3
  maxMotorTorque   dd ?
  motorVelocity    b3Vec3
                   rb 4
ends

struct b3WeldJointDef
  base                b3JointDef
  linearHertz         dd ?
  angularHertz        dd ?
  linearDampingRatio  dd ?
  angularDampingRatio dd ?
ends

struct b3WheelJointDef
  base                   b3JointDef
  enableSuspensionSpring db ?
                         rb 3
  suspensionHertz        dd ?
  suspensionDampingRatio dd ?
  enableSuspensionLimit  db ?
                         rb 3
  lowerSuspensionLimit   dd ?
  upperSuspensionLimit   dd ?
  enableSpinMotor        db ?
                         rb 3
  maxSpinTorque          dd ?
  spinSpeed              dd ?
  enableSteering         db ?
                         rb 3
  steeringHertz          dd ?
  steeringDampingRatio   dd ?
  targetSteeringAngle    dd ?
  maxSteeringTorque      dd ?
  enableSteeringLimit    db ?
                         rb 3
  lowerSteeringLimit     dd ?
  upperSteeringLimit     dd ?
                         rb 4
ends

struct b3ExplosionDef
  maskBits       dq ?
  position       b3Pos
  radius         dd ?
  falloff        dd ?
  impulsePerArea dd ?
ends

struct b3SensorBeginTouchEvent
  sensorShapeId  b3ShapeId
  visitorShapeId b3ShapeId
ends

struct b3SensorEndTouchEvent
  sensorShapeId  b3ShapeId
  visitorShapeId b3ShapeId
ends

struct b3SensorEvents
  beginEvents dq ?
  endEvents   dq ?
  beginCount  dd ?
  endCount    dd ?
ends

struct b3ContactBeginTouchEvent
  shapeIdA  b3ShapeId
  shapeIdB  b3ShapeId
  contactId b3ContactId
ends

struct b3ContactEndTouchEvent
  shapeIdA  b3ShapeId
  shapeIdB  b3ShapeId
  contactId b3ContactId
ends

struct b3ContactHitEvent
  shapeIdA        b3ShapeId
  shapeIdB        b3ShapeId
  contactId       b3ContactId
  point           b3Pos
  normal          b3Vec3
  approachSpeed   dd ?
  userMaterialIdA dq ?
  userMaterialIdB dq ?
ends

struct b3ContactEvents
  beginEvents dq ?
  endEvents   dq ?
  hitEvents   dq ?
  beginCount  dd ?
  endCount    dd ?
  hitCount    dd ?
              rb 4
ends

struct b3BodyMoveEvent
  userData   dq ?
  transform  b3WorldTransform
  bodyId     b3BodyId
  fellAsleep db ?
             rb 3
ends

struct b3BodyEvents
  moveEvents dq ?
  moveCount  dd ?
             rb 4
ends

struct b3JointEvent
  jointId  b3JointId
  userData dq ?
ends

struct b3JointEvents
  jointEvents dq ?
  count       dd ?
              rb 4
ends

struct b3ContactData
  contactId     b3ContactId
  shapeIdA      b3ShapeId
  shapeIdB      b3ShapeId
                rb 4
  manifolds     dq ?
  manifoldCount dd ?
                rb 4
ends

struct b3QueryFilter
  categoryBits dq ?
  maskBits     dq ?
  id           dq ?
  name         dq ?
ends

struct b3RayCastInput
  origin      b3Vec3
  translation b3Vec3
  maxFraction dd ?
ends

struct b3RayResult
  shapeId        b3ShapeId
  point          b3Pos
  normal         b3Vec3
  userMaterialId dq ?
  fraction       dd ?
  triangleIndex  dd ?
  childIndex     dd ?
  nodeVisits     dd ?
  leafVisits     dd ?
  hit            db ?
                 rb 3
ends

struct b3ShapeProxy
  points dq ?
  count  dd ?
  radius dd ?
ends

struct b3ShapeCastInput
  proxy       b3ShapeProxy
  translation b3Vec3
  maxFraction dd ?
  canEncroach db ?
              rb 7
ends

struct b3BoxCastInput
  box         b3AABB
  translation b3Vec3
  maxFraction dd ?
ends

struct b3CastOutput
  normal        b3Vec3
  point         b3Vec3
  fraction      dd ?
  iterations    dd ?
  triangleIndex dd ?
  childIndex    dd ?
  materialIndex dd ?
  hit           db ?
                rb 3
ends

; single precision typedef of b3CastOutput
struct b3WorldCastOutput
  normal        b3Vec3
  point         b3Vec3
  fraction      dd ?
  iterations    dd ?
  triangleIndex dd ?
  childIndex    dd ?
  materialIndex dd ?
  hit           db ?
                rb 3
ends

struct b3BodyCastResult
  shapeId        b3ShapeId
  point          b3Pos
  normal         b3Vec3
  fraction       dd ?
  triangleIndex  dd ?
  userMaterialId dq ?
  iterations     dd ?
  hit            db ?
                 rb 3
ends

struct b3SimplexCache
  metric dd ?
  count  dw ?
  indexA rb 4
  indexB rb 4
         rb 2
ends

struct b3ShapeCastPairInput
  proxyA       b3ShapeProxy
  proxyB       b3ShapeProxy
  transform    b3Transform
  translationB b3Vec3
  maxFraction  dd ?
  canEncroach  db ?
               rb 3
ends

struct b3DistanceInput
  proxyA    b3ShapeProxy
  proxyB    b3ShapeProxy
  transform b3Transform
  useRadii  db ?
            rb 3
ends

struct b3DistanceOutput
  pointA       b3Vec3
  pointB       b3Vec3
  normal       b3Vec3
  distance     dd ?
  iterations   dd ?
  simplexCount dd ?
ends

struct b3SimplexVertex
  wA     b3Vec3
  wB     b3Vec3
  w      b3Vec3
  a      dd ?
  indexA dd ?
  indexB dd ?
ends

struct b3Simplex
  vertices rb 4*sizeof.b3SimplexVertex
  count    dd ?
ends

struct b3Sweep
  localCenter b3Vec3
  c1          b3Vec3
  c2          b3Vec3
  q1          b3Quat
  q2          b3Quat
ends

struct b3TOIInput
  proxyA      b3ShapeProxy
  proxyB      b3ShapeProxy
  sweepA      b3Sweep
  sweepB      b3Sweep
  maxFraction dd ?
              rb 4
ends

struct b3TOIOutput
  state              dd ?
  point              b3Vec3
  normal             b3Vec3
  fraction           dd ?
  distance           dd ?
  distanceIterations dd ?
  pushBackIterations dd ?
  rootIterations     dd ?
  usedFallback       db ?
                     rb 3
ends

struct b3TreeNodeChildren
  child1 dd ?
  child2 dd ?
ends

struct b3TreeNode
  aabb         b3AABB
  categoryBits dq ?
  union
    children b3TreeNodeChildren
    userData dq ?
  ends
  union
    parent dd ?
    next   dd ?
  ends
  height dw ?
  flags  dw ?
ends

struct b3DynamicTree
  version         dq ?
  nodes           dq ?
  root            dd ?
  nodeCount       dd ?
  nodeCapacity    dd ?
  proxyCount      dd ?
  freeList        dd ?
                  rb 4
  leafIndices     dq ?
  leafBoxes       dq ?
  leafCenters     dq ?
  binIndices      dq ?
  rebuildCapacity dd ?
                  rb 4
ends

struct b3TreeStats
  nodeVisits dd ?
  leafVisits dd ?
ends

struct b3PlaneResult
  plane b3Plane
  point b3Vec3
ends

struct b3CollisionPlane
  plane        b3Plane
  pushLimit    dd ?
  label push: dword     ; `push` collides with the x86 instruction name
  rb 4
  clipVelocity db ?
               rb 3
ends

struct b3PlaneSolverResult
  delta          b3Vec3
  iterationCount dd ?
ends

struct b3BodyPlaneResult
  shapeId b3ShapeId
  result  b3PlaneResult
ends

struct b3MassData
  mass    dd ?
  center  b3Vec3
  inertia b3Matrix3
ends

struct b3Sphere
  center b3Vec3
  radius dd ?
ends

struct b3Capsule
  center1 b3Vec3
  center2 b3Vec3
  radius  dd ?
ends

struct b3HullVertex
  edge db ?
ends

struct b3HullHalfEdge
  next   db ?
  twin   db ?
  origin db ?
  face   db ?
ends

struct b3HullFace
  edge db ?
ends

struct b3HullData
  version        dq ?
  byteCount      dd ?
  hash           dd ?
  aabb           b3AABB
  surfaceArea    dd ?
  volume         dd ?
  innerRadius    dd ?
  center         b3Vec3
  centralInertia b3Matrix3
  vertexCount    dd ?
  vertexOffset   dd ?
  pointOffset    dd ?
  edgeCount      dd ?
  edgeOffset     dd ?
  faceCount      dd ?
  faceOffset     dd ?
  planeOffset    dd ?
  padding        dd ?
ends

struct b3BoxHull
  base        b3HullData
  boxVertices rb 8*sizeof.b3HullVertex
  boxPoints   rb 8*sizeof.b3Vec3
  boxEdges    rb 24*sizeof.b3HullHalfEdge
  boxFaces    rb 6*sizeof.b3HullFace
  padding     rb 2
  boxPlanes   rb 6*sizeof.b3Plane
ends

struct b3MeshDef
  vertices        dq ?
  indices         dq ?
  materialIndices dq ?
  weldTolerance   dd ?
  vertexCount     dd ?
  triangleCount   dd ?
  weldVertices    db ?
  useMedianSplit  db ?
  identifyEdges   db ?
                  rb 1
ends

struct b3MeshTriangle
  index1 dd ?
  index2 dd ?
  index3 dd ?
ends

struct b3MeshNode
  lowerBound     b3Vec3
  ; bit field union: axis/type in low 2 bits, childOffset/triangleCount in
  ; high 30 bits; `data` collides with the PE format directive
  label data: dword
  rb 4
  upperBound     b3Vec3
  triangleOffset dd ?
ends

struct b3MeshData
  version         dq ?
  byteCount       dd ?
  hash            dd ?
  bounds          b3AABB
  surfaceArea     dd ?
  treeHeight      dd ?
  degenerateCount dd ?
  nodeOffset      dd ?
  nodeCount       dd ?
  vertexOffset    dd ?
  vertexCount     dd ?
  triangleOffset  dd ?
  triangleCount   dd ?
  materialOffset  dd ?
  materialCount   dd ?
  flagsOffset     dd ?
ends

struct b3Mesh
  label data: qword     ; `data` collides with the PE format directive
  rb 8
  scale b3Vec3
        rb 4
ends

struct b3HeightFieldDef
  heights             dq ?
  materialIndices     dq ?
  scale               b3Vec3
  countX              dd ?
  countZ              dd ?
  globalMinimumHeight dd ?
  globalMaximumHeight dd ?
  clockwiseWinding    db ?
                      rb 3
ends

struct b3HeightFieldData
  version        dq ?
  byteCount      dd ?
  hash           dd ?
  aabb           b3AABB
  minHeight      dd ?
  maxHeight      dd ?
  heightScale    dd ?
  scale          b3Vec3
  columnCount    dd ?
  rowCount       dd ?
  heightsOffset  dd ?
  materialOffset dd ?
  flagsOffset    dd ?
  clockwise      db ?
  padding        rb 3
ends

struct b3CompoundCapsuleDef
  capsule  b3Capsule
           rb 4
  material b3SurfaceMaterial
ends

struct b3CompoundHullDef
  hull      dq ?
  transform b3Transform
            rb 4
  material  b3SurfaceMaterial
ends

struct b3CompoundMeshDef
  meshData      dq ?
  transform     b3Transform
  scale         b3Vec3
  materials     dq ?
  materialCount dd ?
                rb 4
ends

struct b3CompoundSphereDef
  sphere   b3Sphere
  material b3SurfaceMaterial
ends

struct b3CompoundDef
  capsules     dq ?
  capsuleCount dd ?
               rb 4
  hulls        dq ?
  hullCount    dd ?
               rb 4
  meshes       dq ?
  meshCount    dd ?
               rb 4
  spheres      dq ?
  sphereCount  dd ?
               rb 4
ends

struct b3CompoundData
  version         dq ?
  byteCount       dd ?
  nodeOffset      dd ?
  tree            b3DynamicTree
  materialOffset  dd ?
  materialCount   dd ?
  capsuleOffset   dd ?
  capsuleCount    dd ?
  hullOffset      dd ?
  hullCount       dd ?
  sharedHullCount dd ?
  meshOffset      dd ?
  meshCount       dd ?
  sharedMeshCount dd ?
  sphereOffset    dd ?
  sphereCount     dd ?
ends

struct b3CompoundCapsule
  capsule       b3Capsule
  materialIndex dd ?
ends

struct b3CompoundHull
  hull          dq ?
  transform     b3Transform
  materialIndex dd ?
ends

struct b3CompoundMesh
  meshData        dq ?
  transform       b3Transform
  scale           b3Vec3
  materialIndices rd B3_MAX_COMPOUND_MESH_MATERIALS
ends

struct b3CompoundSphere
  sphere        b3Sphere
  materialIndex dd ?
ends

struct b3ChildShape
  union
    capsule b3Capsule
    hull    dq ?
    mesh    b3Mesh
    sphere  b3Sphere
            rb 32   ; union padded to pointer alignment
  ends
  transform       b3Transform
  materialIndices rd B3_MAX_COMPOUND_MESH_MATERIALS
  type            dd ?
ends

struct b3ManifoldPoint
  anchorA            b3Vec3
  anchorB            b3Vec3
  separation         dd ?
  baseSeparation     dd ?
  normalImpulse      dd ?
  totalNormalImpulse dd ?
  normalVelocity     dd ?
  featureId          dd ?
  triangleIndex      dd ?
  persisted          db ?
                     rb 3
ends

struct b3Manifold
  points          rb B3_MAX_MANIFOLD_POINTS*sizeof.b3ManifoldPoint
  normal          b3Vec3
  twistImpulse    dd ?
  frictionImpulse b3Vec3
  rollingImpulse  b3Vec3
  pointCount      dd ?
ends

struct b3SATCache
  separation dd ?
  type       db ?
  indexA     db ?
  indexB     db ?
  hit        db ?
ends

struct b3FeaturePair
  owner1 db ?
  index1 db ?
  owner2 db ?
  index2 db ?
ends

struct b3LocalManifoldPoint
  point         b3Vec3
  separation    dd ?
  pair          b3FeaturePair
  triangleIndex dd ?
ends

struct b3LocalManifold
  normal          b3Vec3
  triangleNormal  b3Vec3
  points          dq ?
  pointCount      dd ?
  triangleIndex   dd ?
  i1              dd ?
  i2              dd ?
  i3              dd ?
  squaredDistance dd ?
  feature         dd ?
  triangleFlags   dd ?
ends

struct b3DebugShape
  shapeId b3ShapeId
  type    dd ?
          rb 4
  union
    capsule     dq ?
    compound    dq ?
    heightField dq ?
    hull        dq ?
    mesh        dq ?
    sphere      dq ?
  ends
ends

struct b3DebugDraw
  DrawShapeFcn        dq ?
  DrawSegmentFcn      dq ?
  DrawTransformFcn    dq ?
  DrawPointFcn        dq ?
  DrawSphereFcn       dq ?
  DrawCapsuleFcn      dq ?
  DrawBoundsFcn       dq ?
  DrawBoxFcn          dq ?
  DrawStringFcn       dq ?
  drawingBounds       b3AABB
  forceScale          dd ?
  jointScale          dd ?
  drawShapes          db ?
  drawJoints          db ?
  drawJointExtras     db ?
  drawBounds          db ?
  drawMass            db ?
  drawBodyNames       db ?
  drawContacts        db ?
                      rb 1
  drawAnchorA         dd ?
  drawGraphColors     db ?
  drawContactFeatures db ?
  drawContactNormals  db ?
  drawContactForces   db ?
  drawFrictionForces  db ?
  drawIslands         db ?
                      rb 6
  context             dq ?
ends

; ---------------------------------------------------------------------------
; box3d.h (recording)

struct b3RecPlayerInfo
  frameCount   dd ?
  workerCount  dd ?
  timeStep     dd ?
  subStepCount dd ?
  lengthScale  dd ?
  bounds       b3AABB
ends

struct b3RecQueryInfo
  type        dd ?
              rb 4
  filter      b3QueryFilter
  aabb        b3AABB
  origin      b3Pos
  translation b3Vec3
  hitCount    dd ?
              rb 4
  key         dq ?
  id          dq ?
  name        dq ?
ends

struct b3RecQueryHit
  shape    b3ShapeId
  point    b3Pos
  normal   b3Vec3
  fraction dd ?
ends
