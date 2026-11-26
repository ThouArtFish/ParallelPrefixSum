#version 430 core

#define N 128u
#define HALF_N 64u
#define LOG2_N 7u

layout(local_size_x = HALF_N, local_size_y = 1, local_size_z = 1) in;

layout(rgba8ui, binding = 0) readonly uniform uimage2D tex_in;
layout(std430, binding = 1) buffer inter_pixels { uvec4[] all_pixels; };
layout(std430, binding = 2) buffer block_sums { uvec4[] sums; };

shared uvec3 pixels[N];

void atomicUVec4Add(uint vec_index, uvec4 vec) {
  for (uint i = 0u; i < 4u; i++)
    atomicAdd(sums[vec_index][i], vec[i]);
}

void main() {
  const ivec2 size = imageSize(tex_in);
  const uint row = gl_WorkGroupID.y;
  const uint block = gl_WorkGroupID.x;
  const uint num_blocks = gl_NumWorkGroups.x;
  const uint block_offset = block * N;
  const uint row_offset = row * N * num_blocks;

  const uvec2 p =
      uvec2(gl_LocalInvocationID.x * 2u, gl_LocalInvocationID.x * 2u + 1u);
  pixels[p.x] = uvec3(all_pixels[block_offset + p.x + row_offset]);
  if (p.y == N - 1u) {
    pixels[p.y] = uvec3(0u);
    for (uint i = block; i < num_blocks; i++)
      atomicUVec4Add(row * num_blocks + i,
                     all_pixels[block_offset + p.y + row_offset]);
  } else {
    pixels[p.y] = uvec3(all_pixels[block_offset + p.y + row_offset]);
  }

  for (int i = int(LOG2_N) - 1; i >= 0; i--) {
    memoryBarrierShared();
    barrier();

    if ((p.x + 1u) % (1u << (i + 1u)) == 0) {
      const uvec3 k = pixels[p.x];
      pixels[p.x] += pixels[p.x - (1u << i)];
      pixels[p.x - (1u << i)] = k;
    }
    if ((p.y + 1u) % (1u << (i + 1u)) == 0) {
      const uvec3 k = pixels[p.y];
      pixels[p.y] += pixels[p.y - (1u << i)];
      pixels[p.y - (1u << i)] = k;
    }
  }

  memoryBarrierShared();
  barrier();

  all_pixels[block_offset + p.x + row_offset] = uvec4(pixels[p.x], 0u);
  all_pixels[block_offset + p.y + row_offset] = uvec4(pixels[p.y], 0u);
}
