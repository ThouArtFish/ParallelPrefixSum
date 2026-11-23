#version 430 core

#define N 256u
#define HALF_N 128u
#define LOG2_N 8u

layout(local_size_x = HALF_N, local_size_y = 1, local_size_z = 1) in;

layout(rgba8ui, binding = 0) writeonly uniform uimage2D tex_out;
layout(std430, binding = 1) buffer inter_pixels { uvec4[] all_pixels; };

shared uvec3 pixels[N];

void main() {
  const uint row = gl_WorkGroupID.y;
  const uint t = gl_LocalInvocationID.x;

  const uvec2 p = uvec2(t * 2u, t * 2u + 1u);
  pixels[p.x] = (p.x == N - 1 ? uvec3(0u) : uvec3(all_pixels[p.x + row * N]));
  pixels[p.y] = (p.y == N - 1 ? uvec3(0u) : uvec3(all_pixels[p.y + row * N]));

  for (int i = int(LOG2_N) - 1; i >= 0; i--) {
    memoryBarrierShared();
    barrier();

    if ((p.x + 1u) % (1u << (i + 1u)) == 0) {
      const uvec3 k = pixels[p.x];
      pixels[p.x] += pixels[p.x - (1u << i)];
      pixels[p.x - (1u << i)] = k;
    } else if ((p.y + 1u) % (1u << (i + 1u)) == 0) {
      const uvec3 k = pixels[p.y];
      pixels[p.y] += pixels[p.y - (1u << i)];
      pixels[p.y - (1u << i)] = k;
    }
  }

  memoryBarrierShared();
  barrier();

  imageStore(
      tex_out, ivec2(p.x, row),
      uvec4(uvec3((vec3(pixels[p.x]) / vec3(pixels[N - 1])) * vec3(255.0)),
            255u));
  imageStore(
      tex_out, ivec2(p.y, row),
      uvec4(uvec3((vec3(pixels[p.y]) / vec3(pixels[N - 1])) * vec3(255.0)),
            255u));
}
