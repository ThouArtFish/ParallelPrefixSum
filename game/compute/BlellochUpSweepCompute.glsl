#version 430 core

#define N 128u
#define HALF_N 64u
#define LOG2_N 7u

layout(local_size_x = HALF_N, local_size_y = 1, local_size_z = 1) in;

layout(rgba8ui, binding = 0) readonly uniform uimage2D tex_in;
layout(std430, binding = 1) buffer inter_pixels { uvec4[] all_pixels; };

shared uvec3 pixels[N];

void main() {
  const ivec2 size = imageSize(tex_in);
  const uint row = gl_WorkGroupID.y;
  const uint block = gl_WorkGroupID.x;
  const uint num_blocks = gl_NumWorkGroups.x;
  const uint block_offset = block * N;
  const uint row_offset = row * N * num_blocks;

  const uvec2 p =
      uvec2(gl_LocalInvocationID.x * 2u, gl_LocalInvocationID.x * 2u + 1u);
  pixels[p.x] = (block_offset + p.x < size.x
                     ? uvec3(imageLoad(tex_in, ivec2(block_offset + p.x, row)))
                     : uvec3(0u));
  pixels[p.y] = (block_offset + p.y < size.y
                     ? uvec3(imageLoad(tex_in, ivec2(block_offset + p.y, row)))
                     : uvec3(0u));

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

  all_pixels[block_offset + p.x + row_offset] = uvec4(pixels[p.x], 0u);
  all_pixels[block_offset + p.y + row_offset] = uvec4(pixels[p.y], 0u);
}
