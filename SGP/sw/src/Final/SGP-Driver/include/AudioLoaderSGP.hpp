#ifndef SUPER_HAXAGON_AUDIO_LOADER_SGP_HPP
#define SUPER_HAXAGON_AUDIO_LOADER_SGP_HPP

#include "Core/Metadata.hpp"
#include "Core/AudioLoader.hpp"
#include "AudioPlayerSGP.hpp"

namespace SuperHaxagon {
	enum class Location;
	class Platform;
	class AudioLoaderSGP : public AudioLoader {
	public:
		explicit AudioLoaderSGP(std::unique_ptr<std::istream> file);
		~AudioLoaderSGP() override = default;

		std::unique_ptr<AudioPlayer> instantiate() override;

	private:
		float _time;
	};
}

#endif //SUPER_HAXAGON_AUDIO_LOADER_SGP_HPP
