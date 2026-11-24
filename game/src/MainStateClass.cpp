#include "../include/MainStateClass.hpp"

MainState::MainState() {
	// Compile shaders
	shaders.addShader<ProgramType::Default>({ "hud_draw", "", TAGShaderManager::DefaultProgramType::HUD_DRAW });
	shaders.addShader<ProgramType::Compute>(ProgramType::Compute{ "compute_upsweep", "BlellochUpSweepCompute.glsl" });
	shaders.addShader<ProgramType::Compute>(ProgramType::Compute{ "compute_downsweep", "BlellochDownSweepCompute.glsl" });

	// Create input texture with uniform colour
	TAGTexLoader::Info start_tex_info{ .width = TEX_DIMENSIONS.x, .height = TEX_DIMENSIONS.y, .nr_channels = PIXEL_STRIDE };
	start_tex_info.data_container.data = new unsigned char[PIXEL_STRIDE * TEX_DIMENSIONS.x * TEX_DIMENSIONS.y]();

	for (size_t i = 0; i < TEX_DIMENSIONS.x * TEX_DIMENSIONS.y; i++) {
		unsigned char* pixel = start_tex_info.data_container.data + PIXEL_STRIDE * i;

		for (size_t j = 0; j < PIXEL_STRIDE; j++) {
			*(pixel + j) = (j < 3 ? (unsigned char)TAGUtil::randomRangeInt<unsigned int>(0u, 255u) : 255u);
		}
	}

	const auto in_tex = TAGTexLoader::textureFromInfo(start_tex_info, "in_tex", { .srgb = true, .mipmap = false });

	// Create empty output texture
	const auto out_tex = TAGTexLoader::emptyTexture("out_tex", TEX_DIMENSIONS.x, TEX_DIMENSIONS.y, PIXEL_STRIDE, { .srgb = true, .mipmap = false });

	// Bind textures and buffers
	glBindImageTexture(0, in_tex.id, 0, GL_FALSE, 0, GL_READ_ONLY, GL_RGBA8UI);
	inter_buffer.bindToShader(1, TAGResourceManager::ShaderBufferType::SHADER_STORAGE, 0);
	block_increment_buffer.bindToShader(2, TAGResourceManager::ShaderBufferType::SHADER_STORAGE, 0);
	glBindImageTexture(3, out_tex.id, 0, GL_FALSE, 0, GL_WRITE_ONLY, GL_RGBA8UI);

	// Dispatch up sweep stage
	TAGShaderManager::Shader compute_shader = shaders.useShader("compute_upsweep");
	glDispatchCompute(block_increment_buffer.getMaxObjects(), TEX_DIMENSIONS.y, 1);

	// Dispatch down sweep stage
	compute_shader = shaders.useShader("compute_downsweep");
	glDispatchCompute(block_increment_buffer.getMaxObjects(), TEX_DIMENSIONS.y, 1);

	// Place memory barrier before rendering
	glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT |
		GL_TEXTURE_FETCH_BARRIER_BIT |
		GL_TEXTURE_UPDATE_BARRIER_BIT);

	// Unbind textures and buffers
	glBindImageTexture(0, 0, 0, GL_FALSE, 0, GL_READ_ONLY, GL_RGBA8UI);
	inter_buffer.unbindFromShader(1, TAGResourceManager::ShaderBufferType::SHADER_STORAGE);
	block_increment_buffer.unbindFromShader(2, TAGResourceManager::ShaderBufferType::SHADER_STORAGE);
	glBindImageTexture(3, 0, 0, GL_FALSE, 0, GL_WRITE_ONLY, GL_RGBA8UI);

	// Delete compute shaders
	shaders.stopShader();
	shaders.deleteShader("compute_downsweep");
	shaders.deleteShader("compute_upsweep");

	// Create quads to display textures
	hud.addImage(in_tex);
	hud.addQuad(
		{
			.position = { 0.03f, 0.1f },
			.dimensions = { 0.45f, 0.45f },
			.image_name = "in_tex"
		}
	);
	hud.addImage(out_tex);
	hud.addQuad(
		{
			.position = { 0.53f, 0.1f },
			.dimensions = { 0.45f, 0.45f },
			.image_name = "out_tex"
		}
	);
}

std::string MainState::mainLoop() {
	if (getKeyState(GLFW_KEY_ESCAPE)) return "END";

	const auto& draw_shader = shaders.useShader("hud_draw");
	hud.drawAll(draw_shader);

	return "CURRENT";
}
