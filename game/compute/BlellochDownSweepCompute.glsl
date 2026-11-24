#version 430 core

#define N 32u
#define HALF_N 16u
#define LOG2_N 5u

layout(local_size_x = HALF_N, local_size_y = 1, local_size_z = 1) in;

layout(rgba8ui, binding = 0) readonly uniform uimage2D tex_in;
layout(std430, binding = 1) buffer inter_pixels { uvec4[] all_pixels; };
layout(std430, binding = 2) buffer block_increments { uvec4[] incr; };
layout(rgba8ui, binding = 3) writeonly uniform uimage2D tex_out;

shared uvec3 pixels[N];

uvec3 totalIncr(uint block, uint num_rows, uint row) {
  uvec4 sum = uvec4(0u);
  for (block; block > 0u; block--)
    sum += incr[(block - 1u) * num_rows + row];
  return uvec3(sum);
}

void main() {
  const ivec2 size = imageSize(tex_in);
  const uint row = gl_WorkGroupID.y;
  const uint block = gl_WorkGroupID.x;
  const uint block_offset = block * N;
  const uint max_pixel = min(N, size.x - block_offset) - 1u;
  bool first_valid = false, second_valid = false;

  const uvec2 p =
      uvec2(gl_LocalInvocationID.x * 2u, gl_LocalInvocationID.x * 2u + 1u);
  if (block_offset + p.x < size.x) {
    pixels[p.x] = uvec3(all_pixels[block_offset + p.x + row * N]);
    first_valid = true;
  }
  if (block_offset + p.y < size.x) {
    if (p.y == max_pixel) {
      pixels[p.y] = uvec3(0u);
      incr[block * size.y + row] = all_pixels[block_offset + p.y + row * N];
    } else {
      pixels[p.y] = uvec3(all_pixels[block_offset + p.y + row * N]);
    }
    second_valid = true;
  }

  for (int i = int(LOG2_N) - 1; i >= 0; i--) {
    memoryBarrierShared();
    barrier();

    if (first_valid && (p.x + 1u) % (1u << (i + 1u)) == 0) {
      const uvec3 k = pixels[p.x];
      pixels[p.x] += pixels[p.x - (1u << i)];
      pixels[p.x - (1u << i)] = k;
    } else if (second_valid && (p.y + 1u) % (1u << (i + 1u)) == 0) {
      const uvec3 k = pixels[p.y];
      pixels[p.y] += pixels[p.y - (1u << i)];
      pixels[p.y - (1u << i)] = k;
    }
  }

  memoryBarrierShared();
  barrier();

  const vec3 total_sum =
      vec3(totalIncr(uint(gl_NumWorkGroups / size.y) + 1u, size.y, row));
  if (first_valid) {
    const uvec3 pixel = uvec3(
        vec3((pixels[p.x] + totalIncr(block, size.y, row)) * uvec3(255u)) /
        total_sum);
    imageStore(tex_out, ivec2(block_offset + p.x, row), uvec4(pixel, 255u));
  }
  if (second_valid) {
    const uvec3 pixel = uvec3(
        vec3((pixels[p.y] + totalIncr(block, size.y, row)) * uvec3(255u)) /
        total_sum);
    imageStore(tex_out, ivec2(block_offset + p.y, row), uvec4(pixel, 255u));
  }
}
