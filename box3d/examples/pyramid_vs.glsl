#version 330 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNormal;

uniform vec3  uPos;    // body world position
uniform vec4  uQuat;   // body rotation quaternion (v.xyz, s)
uniform vec3  uHalf;   // box half extents
uniform vec3  uColor;
uniform float uAspect;

out vec3 vColor;

// same formula as Box3D's b3RotateVector
vec3 rotate(vec4 q, vec3 v)
{
    return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}

void main()
{
    vec3 world = uPos + rotate(uQuat, aPos * uHalf);

    // fixed camera looking at the pyramid
    vec3 eye = vec3(13.0, 8.0, 16.0);
    vec3 target = vec3(0.0, 2.5, 0.0);
    vec3 f = normalize(target - eye);
    vec3 r = normalize(cross(f, vec3(0.0, 1.0, 0.0)));
    vec3 u = cross(r, f);
    vec3 e = world - eye;
    vec3 v = vec3(dot(e, r), dot(e, u), dot(e, f)); // v.z > 0 in front

    // simple lambert lighting in world space
    vec3 n = rotate(uQuat, aNormal);
    float light = 0.35 + 0.65 * max(dot(n, normalize(vec3(0.4, 0.8, 0.3))), 0.0);
    vColor = uColor * light;

    float fl = 1.7;                 // focal length
    float zn = 0.1, zf = 200.0;
    gl_Position = vec4(v.x * fl / uAspect, v.y * fl,
                       (v.z * (zf + zn) - 2.0 * zf * zn) / (zf - zn), v.z);
}
