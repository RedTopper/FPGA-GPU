#ifndef SUPER_HAXAGON_PLATFORM_SGP_HPP
#define SUPER_HAXAGON_PLATFORM_SGP_HPP

#include "Core/Platform.hpp"

#include <deque>
#include <fstream>

struct GLFWwindow;
namespace SuperHaxagon {
	class Font;

	class PlatformSGP : public Platform {
	public:
		explicit PlatformSGP(Dbg dbg);
		PlatformSGP(PlatformSGP&) = delete;
		~PlatformSGP() override;

		bool loop() override;
		float getDilation() override;

		std::string getPath(const std::string& partial, Location location) override;
		std::unique_ptr<Font> loadFont(const std::string& partial, int size) override;
		std::unique_ptr<AudioLoader> loadAudio(const std::string& partial, Stream stream, Location location) override;

		void playSFX(AudioLoader& audio) override;
		void playBGM(AudioLoader& audio) override;

		std::string getButtonName(const Buttons& button) override;
		Buttons getPressed() override;

		std::unique_ptr<Twist> getTwister() override;

		void shutdown() override;

		void message(Dbg dbg, const std::string& where, const std::string& message) override;

	private:
		bool _loaded = false;
		float _z = 0.0f;

		std::ofstream _console;
		std::deque<std::pair<Dbg, std::string>> _messages{};

		GLFWwindow* _window;
	};
}

#endif //SUPER_HAXAGON_PLATFORM_SGP_HPP
