#include <BaseStateClass.hpp>
#include "../include/MainStateClass.hpp"

int main() {
	TAGBaseState::initGame(TAGBaseState::GameInitializer(1280, 720, "Parallel Prefix Sum Output"));

	TAGResourceManager::asset_path = "../../../game/compute/";
	TAGBaseState::setWindowClearColour({ 0.306f, 0.176f, 0.839f });

	TAGBaseState::addState<MainState>("MAIN");

	return TAGBaseState::runGame();
}