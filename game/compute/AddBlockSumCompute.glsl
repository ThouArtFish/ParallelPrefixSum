#version 430 core

#define N 128u
#define HALF_N 64u

layout(local_size_x = HALF_N, local_size_y = 1, local_size_z = 1) in;

layout(std430, binding = 1) buffer inter_pixels { uvec4[] all_pixels; };
layout(std430, binding = 2) buffer block_sums { uvec4[] sums; };
layout(rgba8ui, binding = 3) writeonly uniform uimage2D tex_out;

shared dvec3 total_sum;
shared dvec3 block_sum_offset;

void main() {
  const ivec2 size = imageSize(tex_out);
  const uint row = gl_WorkGroupID.y;
  const uint block = gl_WorkGroupID.x;
  const uint num_blocks = gl_NumWorkGroups.x;
  const uint block_offset = block * N;
  const uint row_offset = row * N * num_blocks;

  if (gl_LocalInvocationID.x == 0u) {
    block_sum_offset =
        (block == 0u ? dvec3(0u) : dvec3(sums[row * num_blocks + block - 1u]));
    total_sum = dvec3(sums[(row + 1u) * num_blocks - 1u]);
  }

  memoryBarrierShared();
  barrier();

  const uvec2 p =
      uvec2(gl_LocalInvocationID.x * 2u, gl_LocalInvocationID.x * 2u + 1u);
  uint array_index = block_offset + p.x + row_offset;
  ivec2 image_coords = ivec2(block_offset + p.x, row);

  const uvec4 pixel =
      uvec4(((dvec3(all_pixels[array_index]) + block_sum_offset) / total_sum) *
                dvec3(255.0),
            255u);
  if (image_coords.x < size.x) {
    const uvec4 pixel = uvec4(
        ((dvec3(all_pixels[array_index]) + block_sum_offset) / total_sum) *
            dvec3(255.0),
        255u);
    imageStore(tex_out, image_coords, pixel);
  }
  array_index = block_offset + p.y + row_offset;
  image_coords = ivec2(block_offset + p.y, row);
  if (image_coords.x < size.x) {
    const uvec4 pixel = uvec4(
        ((dvec3(all_pixels[array_index]) + block_sum_offset) / total_sum) *
            dvec3(255.0),
        255u);
    imageStore(tex_out, image_coords, pixel);
  }
}
