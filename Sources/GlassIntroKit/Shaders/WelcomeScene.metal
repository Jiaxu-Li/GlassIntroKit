//===--- WelcomeScene.metal - GlassIntroKit ---------------------------------===//
//
// This source file is part of the GlassIntroKit open source project
//
// Copyright (c) 2026 Jiaxu Li
// Licensed under the Apache License, Version 2.0
//
// See LICENSE for license information
//
//===----------------------------------------------------------------------===//

#include <metal_stdlib>
using namespace metal;

// The welcome's rendering page: one object on a studio floor, ray marched
// in real time. The object is a rounded cube, a sphere, a standing ring, a
// capsule, or a cylinder, in a colour of the app's choosing, turned, tipped,
// and lifted as its motion has it. The same scene is drawn at four levels, and the level changes
// where a sweep line has passed:
//   0  flat 2D: the cube's face as a shape
//   1  3D: form, perspective, and direct light
//   2  shadows, ambient occlusion, and physically based highlights
//   3  reflections, bounce light, and a glossy floor

namespace welcome {

constant float cubeHalf = 0.42f;
constant float cubeRound = 0.05f;
constant float3 keyDirection = float3(-0.52f, 0.74f, -0.42f);
constant float3 keyColor = float3(1.0f, 0.93f, 0.84f);
constant float3 skyColor = float3(0.42f, 0.50f, 0.62f);
constant float3 backgroundColor = float3(0.045f, 0.047f, 0.055f);
constant float3 fillDirection = float3(0.78f, 0.28f, -0.56f);
constant float3 fillColor = float3(0.55f, 0.65f, 0.85f);

/// The object and where it is: its shape, its turn about the vertical, its
/// tip toward the camera, and how far it floats above the floor.
struct Pose {
    int shape;
    float yaw;
    float pitch;
    float lift;
};

/// A point in the object's own space: lifted, turned, and tipped back.
static float3 toObject(float3 p, Pose pose) {
    p.y -= pose.lift;
    float c = cos(pose.yaw);
    float s = sin(pose.yaw);
    p = float3(c * p.x + s * p.z, p.y, -s * p.x + c * p.z);
    float cp = cos(pose.pitch);
    float sp = sin(pose.pitch);
    return float3(p.x, cp * p.y - sp * p.z, sp * p.y + cp * p.z);
}

/// The object's distance, every shape filling the same half-size so that
/// it rests on the floor.
static float objectDistance(float3 p, Pose pose) {
    float3 q = toObject(p, pose);
    switch (pose.shape) {
    case 1:
        // A sphere.
        return length(q) - cubeHalf;
    case 2: {
        // A ring standing on its edge.
        float2 t = float2(length(q.xy) - 0.29f, q.z);
        return length(t) - 0.13f;
    }
    case 3: {
        // An upright capsule.
        float3 a = q - float3(0.0f, clamp(q.y, -0.16f, 0.16f), 0.0f);
        return length(a) - 0.26f;
    }
    case 4: {
        // An upright cylinder with softened rims.
        float2 d = float2(length(q.xz), abs(q.y)) - float2(0.34f - 0.05f, cubeHalf - 0.05f);
        return min(max(d.x, d.y), 0.0f) + length(max(d, 0.0f)) - 0.05f;
    }
    default: {
        float3 b = abs(q) - float3(cubeHalf - cubeRound);
        return length(max(b, 0.0f)) + min(max(b.x, max(b.y, b.z)), 0.0f) - cubeRound;
    }
    }
}

static float floorDistance(float3 p) {
    return p.y + cubeHalf;
}

/// The nearest surface; `isObject` says which it is.
static float sceneDistance(float3 p, Pose pose, thread bool &isObject) {
    float cube = objectDistance(p, pose);
    float ground = floorDistance(p);
    isObject = cube < ground;
    return min(cube, ground);
}

static float3 objectNormal(float3 p, Pose pose) {
    const float e = 0.0015f;
    float3 n = float3(
        objectDistance(p + float3(e, 0, 0), pose) - objectDistance(p - float3(e, 0, 0), pose),
        objectDistance(p + float3(0, e, 0), pose) - objectDistance(p - float3(0, e, 0), pose),
        objectDistance(p + float3(0, 0, e), pose) - objectDistance(p - float3(0, 0, e), pose)
    );
    return n * rsqrt(max(dot(n, n), 1e-12f));
}

/// Marches to the nearest surface; returns the distance, or -1 on a miss.
static float march(float3 origin, float3 direction, Pose pose, thread bool &isObject) {
    float t = 0.0f;
    for (int step = 0; step < 96; ++step) {
        float d = sceneDistance(origin + direction * t, pose, isObject);
        if (d < 0.0008f * max(t, 1.0f)) {
            return t;
        }
        t += d;
        if (t > 24.0f) {
            break;
        }
    }
    return -1.0f;
}

/// Marches toward the cube alone, for reflections off the floor.
static float marchObject(float3 origin, float3 direction, Pose pose) {
    float t = 0.0f;
    for (int step = 0; step < 64; ++step) {
        float d = objectDistance(origin + direction * t, pose);
        if (d < 0.001f) {
            return t;
        }
        t += d;
        if (t > 8.0f) {
            break;
        }
    }
    return -1.0f;
}

/// A soft shadow toward the key light, with a penumbra that widens with
/// distance as an area light's does.
static float softShadow(float3 origin, float3 direction, Pose pose) {
    float light = 1.0f;
    float t = 0.02f;
    for (int step = 0; step < 48; ++step) {
        float d = objectDistance(origin + direction * t, pose);
        light = min(light, 9.0f * d / t);
        t += clamp(d, 0.01f, 0.25f);
        if (light < 0.001f || t > 6.0f) {
            break;
        }
    }
    light = clamp(light, 0.0f, 1.0f);
    return light * light * (3.0f - 2.0f * light);
}

static float ambientOcclusion(float3 p, float3 n, Pose pose) {
    float occlusion = 0.0f;
    float weight = 1.0f;
    for (int step = 1; step <= 5; ++step) {
        float h = 0.03f + 0.07f * float(step);
        bool isObject;
        float d = sceneDistance(p + n * h, pose, isObject);
        occlusion += (h - d) * weight;
        weight *= 0.7f;
    }
    return clamp(1.0f - 1.8f * occlusion, 0.0f, 1.0f);
}

/// The studio around the scene: dark, with a large softbox at the key
/// light, as reflections see it.
static float3 environment(float3 direction) {
    float3 key = normalize(keyDirection);
    float softbox = pow(max(dot(direction, key), 0.0f), 24.0f);
    float overhead = smoothstep(-0.1f, 0.9f, direction.y);
    return backgroundColor + skyColor * 0.10f * overhead + keyColor * 2.2f * softbox;
}

static float3 fresnel(float3 f0, float cosine) {
    return f0 + (1.0f - f0) * pow(1.0f - clamp(cosine, 0.0f, 1.0f), 5.0f);
}

/// A GGX highlight from the key light.
static float3 highlight(float3 n, float3 v, float3 l, float roughness, float3 f0) {
    float3 h = normalize(v + l);
    float nh = max(dot(n, h), 0.0f);
    float nl = max(dot(n, l), 0.0f);
    float nv = max(dot(n, v), 1e-4f);
    float a = roughness * roughness;
    float a2 = a * a;
    float denominator = nh * nh * (a2 - 1.0f) + 1.0f;
    float distribution = a2 / (M_PI_F * denominator * denominator);
    float k = (roughness + 1.0f) * (roughness + 1.0f) / 8.0f;
    float visibility = 1.0f / ((nl * (1.0f - k) + k) * (nv * (1.0f - k) + k));
    return fresnel(f0, max(dot(h, v), 0.0f)) * distribution * visibility * nl / 4.0f;
}

/// The cube's surface at `level`.
static float3 shadeObject(float3 hit, float3 v, Pose pose, float3 albedo, int level) {
    float3 n = objectNormal(hit, pose);
    // The march stops within a tolerance of the surface; settling onto it
    // keeps the occlusion and shadow samples from banding across a face.
    float3 p = hit - n * objectDistance(hit, pose);
    float3 l = normalize(keyDirection);
    float diffuse = max(dot(n, l), 0.0f);
    float sky = 0.5f + 0.5f * n.y;
    if (level == 1) {
        return albedo * (keyColor * diffuse * 0.7f + skyColor * sky * 0.12f);
    }
    float shadow = softShadow(p + n * 0.003f, l, pose);
    float occlusion = ambientOcclusion(p, n, pose);
    float roughness = 0.38f;
    float3 f0 = float3(0.04f);
    float3 color = albedo / M_PI_F * keyColor * diffuse * shadow * 3.0f;
    color += highlight(n, v, l, roughness, f0) * keyColor * shadow * 3.0f;
    color += albedo * skyColor * sky * 0.22f * occlusion;
    if (level >= 3) {
        // Light the lit floor throws back onto the cube's sides, strongest
        // near the ground.
        float height = clamp((p.y + cubeHalf) / (2.0f * cubeHalf), 0.0f, 1.0f);
        float bounce = clamp(0.5f - 0.5f * n.y, 0.0f, 1.0f) * (1.0f - 0.6f * height);
        color += albedo * float3(0.34f, 0.30f, 0.26f) * 0.45f * bounce * occlusion;
        // A large, dim, cool fill from the other side.
        float3 f = normalize(fillDirection);
        color += albedo / M_PI_F * fillColor * max(dot(n, f), 0.0f) * 0.45f * occlusion;
        color += highlight(n, v, f, 0.5f, f0) * fillColor * 0.4f;
        float3 r = reflect(-v, n);
        color += environment(r) * fresnel(f0, dot(n, v)) * 1.2f * occlusion;
    }
    return color;
}

/// The floor at `level`.
static float3 shadeFloor(float3 hit, float3 v, float distance, Pose pose, float3 objectAlbedo, int level) {
    float3 n = float3(0, 1, 0);
    float3 p = float3(hit.x, -cubeHalf, hit.z);
    float3 l = normalize(keyDirection);
    float3 albedo = float3(0.16f, 0.155f, 0.15f);
    float3 color;
    if (level == 1) {
        color = albedo * (keyColor * l.y * 0.7f + skyColor * 0.12f);
    } else {
        float shadow = softShadow(p + n * 0.003f, l, pose);
        float occlusion = ambientOcclusion(p, n, pose);
        color = albedo / M_PI_F * keyColor * l.y * shadow * 3.0f;
        color += albedo * skyColor * 0.22f * occlusion;
        if (level >= 3) {
            // A satin floor: the cube shows in it, softening with distance
            // from the contact.
            float3 r = reflect(-v, n);
            float cosine = max(dot(n, v), 0.0f);
            float3 reflectance = fresnel(float3(0.04f), cosine) * 3.2f;
            float t = marchObject(p + n * 0.002f, r, pose);
            float3 reflected = environment(r);
            if (t > 0.0f) {
                float3 q = p + r * t;
                // Glossy, so the reflection fades as it leaves the contact.
                reflected = shadeObject(q, -r, pose, objectAlbedo, 3) * exp(-1.1f * t);
            }
            color += reflected * reflectance * occlusion;
            float3 f = normalize(fillDirection);
            color += albedo / M_PI_F * fillColor * f.y * 0.45f * occlusion;
        }
    }
    // The floor runs away into the dark studio.
    float fog = 1.0f - exp(-0.035f * distance * distance);
    return mix(color, backgroundColor, fog);
}

static float3 tonemap(float3 color) {
    // ACES fitted curve.
    color = max(color, 0.0f);
    float3 mapped = (color * (2.51f * color + 0.03f)) / (color * (2.43f * color + 0.59f) + 0.14f);
    return pow(clamp(mapped, 0.0f, 1.0f), float3(1.0f / 2.2f));
}

/// The object's outline seen straight on, as a flat shape.
static float3 flatShape(float2 uv, Pose pose, float3 albedo, float pixel) {
    uv.y -= pose.lift * 0.36f;
    float c = cos(pose.yaw);
    float s = sin(pose.yaw);
    float distance;
    switch (pose.shape) {
    case 1:
        distance = length(uv) - 0.15f;
        break;
    case 2:
        distance = abs(length(uv) - 0.105f) - 0.045f;
        break;
    case 3: {
        float2 a = uv - float2(0.0f, clamp(uv.y, -0.06f, 0.06f));
        distance = length(a) - 0.093f;
        break;
    }
    case 4: {
        float2 d = abs(uv) - float2(0.12f * (0.75f + 0.25f * abs(c)), 0.15f);
        distance = length(max(d, 0.0f)) + min(max(d.x, d.y), 0.0f) - 0.015f;
        break;
    }
    default: {
        float2 q = float2(c * uv.x - s * uv.y, s * uv.x + c * uv.y);
        float2 d = abs(q) - float2(0.15f);
        distance = length(max(d, 0.0f)) + min(max(d.x, d.y), 0.0f) - 0.02f;
        break;
    }
    }
    float coverage = 1.0f - smoothstep(-pixel, pixel, distance);
    return mix(float3(0.09f, 0.09f, 0.10f), pow(albedo, float3(1.0f / 2.2f)), coverage);
}

} // namespace welcome

/// - Parameters:
///   - size: the canvas size in points.
///   - center: where the object sits, as a fraction of the canvas.
///   - scale: how many points the scene's unit spans: the smaller of the
///     canvas's sides, so a tall phone shows the object as a wide window does.
///   - shape: 0 cube, 1 sphere, 2 ring, 3 capsule, 4 cylinder.
///   - albedo: the object's colour, linear.
///   - yaw: the object's turn about its vertical axis, in radians.
///   - pitch: its tip toward the camera, in radians.
///   - lift: how far it floats above the floor, in object half-sizes.
///   - level: the level left of the sweep line has; the right keeps one less.
///   - sweep: the sweep line's position as a fraction of the width.
[[ stitchable ]] half4 welcomeScene(float2 position, half4 color, float2 size, float2 center, float scale,
                                    float shape, float3 albedo, float yaw, float pitch, float lift,
                                    float level, float sweep) {
    scale = max(scale, 1.0f);
    float2 uv = (position - center * size) / scale;
    uv.y = -uv.y;
    int base = int(level + 0.5f);
    int shown = position.x < sweep * size.x ? base : max(base - 1, 0);
    welcome::Pose pose = { int(shape + 0.5f), yaw, pitch, lift * welcome::cubeHalf };

    if (shown == 0) {
        return half4(half3(welcome::flatShape(uv, pose, albedo, 1.5f / scale)), 1.0h);
    }

    // A camera a little above the object, looking slightly down.
    float3 origin = float3(0.0f, 1.15f, -5.8f);
    float3 target = float3(0.0f, -0.05f, 0.0f);
    float3 forward = normalize(target - origin);
    float3 right = normalize(cross(float3(0, 1, 0), forward));
    float3 up = cross(forward, right);
    float3 direction = normalize(forward * 2.2f + right * uv.x + up * uv.y);

    bool isObject = false;
    float t = welcome::march(origin, direction, pose, isObject);
    float3 result = welcome::backgroundColor;
    if (t > 0.0f) {
        float3 p = origin + direction * t;
        result = isObject
            ? welcome::shadeObject(p, -direction, pose, albedo, shown)
            : welcome::shadeFloor(p, -direction, t, pose, albedo, shown);
    }
    if (shown >= 2) {
        // A lens's falloff toward the corners.
        float vignette = 1.0f - 0.35f * dot(uv, uv);
        result *= clamp(vignette, 0.0f, 1.0f);
    }
    // A little noise below one step of 8-bit colour keeps the slow studio
    // gradients from banding.
    float noise = fract(sin(dot(position, float2(12.9898f, 78.233f))) * 43758.5453f) - 0.5f;
    float3 mapped = welcome::tonemap(result * (shown >= 2 ? 1.0f : 0.75f)) + noise / 255.0f;
    return half4(half3(mapped), 1.0h);
}
