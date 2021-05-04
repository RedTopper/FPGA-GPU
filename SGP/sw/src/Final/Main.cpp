#include "Core/Game.hpp"
#include "Core/Platform.hpp" 
#include "PlatformSGP.hpp"

namespace SuperHaxagon {
	std::unique_ptr<Platform> getPlatform() {
		return std::make_unique<PlatformSGP>(Dbg::INFO);
	}
}

#ifdef _WIN64
int WinMain() {
#else
int main(int, char**) {
#endif
	const auto platform = SuperHaxagon::getPlatform();
	platform->message(SuperHaxagon::Dbg::INFO, "main", "starting main");

	if (platform->loop()) {
		SuperHaxagon::Game game(*platform);
		game.run();
	}

	platform->message(SuperHaxagon::Dbg::INFO, "main", "stopping main");
	platform->shutdown();

	return 0;
}
