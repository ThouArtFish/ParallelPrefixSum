#version 430 core

#define N 256u
#define HALF_N 128u
#define LOG2_N 8u

layout(local_size_x = HALF_N, local_size_y = 1, local_size_z = 1) in;

layout(rgba8ui, binding = 0) readonly uniform uimage2D tex_in;
layout(std430, binding = 1) buffer inter_pixels { uvec4[] all_pixels; };

shared uvec3 pixels[N];

void main() {
  const uint row = gl_WorkGroupID.y;
  const uint t = gl_LocalInvocationID.x;

  const uvec2 p = uvec2(t * 2u, t * 2u + 1u);
  pixels[p.x] = uvec3(imageLoad(tex_in, ivec2(p.x, row)));
  pixels[p.y] = uvec3(imageLoad(tex_in, ivec2(p.y, row)));

  for (uint i = 0; i < LOG2_N; i++) {
    memoryBarrierShared();
    barrier();

    if ((p.x + 1u) % (1u << (i + 1u)) == 0) {
      pixels[p.x] += pixels[p.x - (1u << i)];
    } else if ((p.y + 1u) % (1u << (i + 1u)) == 0) {
      pixels[p.y] += pixels[p.y - (1u << i)];
    }
  }

  memoryBarrierShared();
  barrier();

  all_pixels[p.x + row * N] = uvec4(pixels[p.x], 255u);
  all_pixels[p.y + row * N] = uvec4(pixels[p.y], 255u);
}
