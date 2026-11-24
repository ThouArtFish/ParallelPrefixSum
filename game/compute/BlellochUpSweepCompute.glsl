#version 430 core

#define N 32u
#define HALF_N 16u
#define LOG2_N 5u

layout(local_size_x = HALF_N, local_size_y = 1, local_size_z = 1) in;

layout(rgba8ui, binding = 0) readonly uniform uimage2D tex_in;
layout(std430, binding = 1) buffer inter_pixels { uvec4[] all_pixels; };

shared uvec3 pixels[N];

void main() {
  const uint width = imageSize(tex_in).x;
  const uint row = gl_WorkGroupID.y;
  const uint block = gl_WorkGroupID.x;
  const uint block_offset = block * N;
  bool first_valid = false, second_valid = false;

  const uvec2 p =
      uvec2(gl_LocalInvocationID.x * 2u, gl_LocalInvocationID.x * 2u + 1u);
  if (block_offset + p.x < width) {
    pixels[p.x] = uvec3(imageLoad(tex_in, ivec2(block_offset + p.x, row)));
    first_valid = true;
  }
  if (block_offset + p.y < width) {
    pixels[p.y] = uvec3(imageLoad(tex_in, ivec2(block_offset + p.y, row)));
    second_valid = true;
  }

  for (uint i = 0; i < LOG2_N; i++) {
    memoryBarrierShared();
    barrier();

    if (first_valid && (p.x + 1u) % (1u << (i + 1u)) == 0) {
      pixels[p.x] += pixels[p.x - (1u << i)];
    }
    if (second_valid && (p.y + 1u) % (1u << (i + 1u)) == 0) {
      pixels[p.y] += pixels[p.y - (1u << i)];
    }
  }

  memoryBarrierShared();
  barrier();

  if (first_valid)
    all_pixels[block_offset + p.x + row * N] = uvec4(pixels[p.x], 255u);
  if (second_valid)
    all_pixels[block_offset + p.y + row * N] = uvec4(pixels[p.y], 255u);
}
