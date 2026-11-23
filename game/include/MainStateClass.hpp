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
	inline constexpr static glm::uvec2 TEX_DIMENSIONS = { 256u, 256u };
	inline constexpr static size_t PIXEL_STRIDE = 4u;

	TAGResourceManager::UnmappedBuffer<glm::uvec4> inter_buffer{
		TEX_DIMENSIONS.x * TEX_DIMENSIONS.y, 1, TAGResourceManager::BufferAccess::STATIC, false
	};
	TAGHUDManager hud{ TAGResourceManager::BufferAccess::STATIC, 2 };
	TAGShaderManager shaders{};
};
