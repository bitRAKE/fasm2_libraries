#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNormal;
// per-instance attributes, streamed from the Box3D move events
layout(location = 2) in vec3 iPos;    // body world position
layout(location = 3) in vec4 iQuat;   // body rotation quaternion (v.xyz, s)
layout(location = 4) in vec3 iHalf;   // box half extents
layout(location = 5) in vec3 iColor;

uniform float uAspect;

out vec3 vColor;

// same formula as Box3D's b3RotateVector
vec3 rotate(vec4 q, vec3 v)
{
    return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}

void main()
{
    vec3 world = iPos + rotate(iQuat, aPos * iHalf);

    // fixed camera looking at the stack
    vec3 eye = vec3(46.0, 32.0, 54.0);
    vec3 target = vec3(0.0, 6.0, 0.0);
    vec3 f = normalize(target - eye);
    vec3 r = normalize(cross(f, vec3(0.0, 1.0, 0.0)));
    vec3 u = cross(r, f);
    vec3 e = world - eye;
    vec3 v = vec3(dot(e, r), dot(e, u), dot(e, f)); // v.z > 0 in front

    // simple lambert lighting in world space
    vec3 n = rotate(iQuat, aNormal);
    float light = 0.35 + 0.65 * max(dot(n, normalize(vec3(0.4, 0.8, 0.3))), 0.0);
    vColor = iColor * light;

    float fl = 1.7;                 // focal length
    float zn = 0.1, zf = 400.0;
    gl_Position = vec4(v.x * fl / uAspect, v.y * fl,
                       (v.z * (zf + zn) - 2.0 * zf * zn) / (zf - zn), v.z);
}
