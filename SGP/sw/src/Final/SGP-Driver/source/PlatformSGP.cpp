#include "PlatformSGP.hpp"

#include "Core/Twist.hpp"
#include "Core/SurfaceUI.hpp"
#include "Core/SurfaceGame.hpp"

#include "AudioLoaderSGP.hpp"
#include "FontSGP.hpp"
#include "SurfaceSGP.hpp"

#include <GLFW/glfw3.h>

#include <iostream>

namespace SuperHaxagon {
	PlatformSGP::PlatformSGP(const Dbg dbg): Platform(dbg) {
		auto surface = std::make_unique<SurfaceSGP>(*this);
		_window = surface->getWindow();
		_surface = std::move(surface);
		_surfaceUI = std::make_unique<SurfaceUI>(_surface.get());
		_surfaceGame = std::make_unique<SurfaceGame>(_surface.get());
		_surfaceGameShadows = std::make_unique<SurfaceGame>(_surface.get());
		PlatformSGP::message(Dbg::INFO, "platform",  "loaded");
	}

	PlatformSGP::~PlatformSGP() {
		PlatformSGP::message(SuperHaxagon::Dbg::INFO, "platform", "shutdown ok");
	}

	bool PlatformSGP::loop() {
		// Check up on the audio status
		if (_bgm && _bgm->isDone()) _bgm->play();
		return glfwGetKey(_window, GLFW_KEY_ESCAPE) != GLFW_PRESS && glfwWindowShouldClose(_window) == 0;
	}

	float PlatformSGP::getDilation() {
		return 1.0;
	}

	void PlatformSGP::playSFX(AudioLoader& audio) {
		auto sfx = audio.instantiate();
		if (!sfx) return;
		sfx->play();
	}

	void PlatformSGP::playBGM(AudioLoader& audio) {
		_bgm = audio.instantiate();
		if (!_bgm) return;
		_bgm->setLoop(true);
		_bgm->play();
	}

	std::string PlatformSGP::getPath(const std::string& partial, const Location location) {
		switch (location) {
			case Location::ROM:
				return std::string("./romfs") + partial;
			case Location::USER:
				return std::string("./sdmc") + partial;
		}

		return "";
	}

	std::unique_ptr<AudioLoader> PlatformSGP::loadAudio(const std::string& partial, Stream stream, const Location location) {
		return std::make_unique<AudioLoaderSGP>(openFile(partial + ".txt", location));
	}

	std::unique_ptr<Font> PlatformSGP::loadFont(const std::string& partial, int size) {
		return std::make_unique<FontSGP>(size);
	}

	std::string PlatformSGP::getButtonName(const Buttons& button) {
		if (button.back) return "B";
		if (button.select) return "A";
		if (button.left) return "LEFT";
		if (button.right) return "RIGHT";
		if (button.quit) return "PLUS";
		return "?";
	}

	Buttons PlatformSGP::getPressed() {
		Buttons buttons{};
		buttons.select = glfwGetKey(_window, GLFW_KEY_SPACE) == GLFW_PRESS;
		buttons.back = glfwGetKey(_window, GLFW_KEY_BACKSPACE) == GLFW_PRESS;
		buttons.quit = glfwGetKey(_window, GLFW_KEY_ESCAPE) == GLFW_PRESS;
		buttons.left = glfwGetKey(_window, GLFW_KEY_A) == GLFW_PRESS;
		buttons.right = glfwGetKey(_window, GLFW_KEY_D) == GLFW_PRESS;
		return buttons;
	}
	
	std::unique_ptr<Twist> PlatformSGP::getTwister() {
		// ALSO a shitty way to do this but it's the best I got.
		const auto a = new std::seed_seq{ time(nullptr) };
		return std::make_unique<Twist>(
			std::unique_ptr<std::seed_seq>(a)
		);
	}

	void PlatformSGP::shutdown() {
		glfwTerminate();
	}

	void PlatformSGP::message(const Dbg dbg, const std::string& where, const std::string& message) {
		if (dbg == Dbg::INFO) {
			std::cout << "[sgp:info] " + where + ": " + message << std::endl;
		} else if (dbg == Dbg::WARN) {
			std::cout << "[sgp:warn] " + where + ": " + message << std::endl;
		} else if (dbg == Dbg::FATAL) {
			std::cerr << "[sgp:fatal] " + where + ": " + message << std::endl;
		}
	}
}
