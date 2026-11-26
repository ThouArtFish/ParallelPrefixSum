#pragma once

#include <BaseStateClass.hpp>
#include <HUDManagerClass.hpp>
#include <UtilClass.hpp>

class MainState : public TAGBaseState {
public:
	MainState();

	std::string mainLoop() override;
	void enter() override {};
	void exit() override {};
	void mouseCallback() override {};
	void framebufferSizeCallback() override {};
	void iconifyCallback() override {};
private:
	inline constexpr static glm::uvec2 TEX_DIMENSIONS = { 512u, 256u };
	inline constexpr static size_t PIXEL_STRIDE = 4u;
	inline constexpr static size_t WORK_GROUP_SIZE = 64u;
	inline const static size_t NUM_WORK_GROUPS_X = (size_t)glm::ceil((float)TEX_DIMENSIONS.x / (float)(WORK_GROUP_SIZE * 2u));

	TAGResourceManager::UnmappedBuffer<glm::uvec4> inter_pixels_buffer{
		NUM_WORK_GROUPS_X * WORK_GROUP_SIZE * 2u * TEX_DIMENSIONS.y, 1, TAGResourceManager::BufferAccess::STATIC, false
	};
	TAGResourceManager::UnmappedBuffer<glm::uvec4> block_sum_buffer{
		NUM_WORK_GROUPS_X * TEX_DIMENSIONS.y, 1, TAGResourceManager::BufferAccess::STATIC, false
	};
	TAGHUDManager hud{ TAGResourceManager::BufferAccess::STATIC, 2 };
	TAGShaderManager shaders{};
};
