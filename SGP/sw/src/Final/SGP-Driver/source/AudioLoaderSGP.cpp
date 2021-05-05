#include "AudioLoaderSGP.hpp"

#include "Core/Platform.hpp"
#include "AudioPlayerSGP.hpp"

#include <fstream>

namespace SuperHaxagon {
	AudioLoaderSGP::AudioLoaderSGP(std::unique_ptr<std::istream> file) {
		Metadata metadata(std::move(file));
		_time = metadata.getMaxTime();
	}

	std::unique_ptr<AudioPlayer> AudioLoaderSGP::instantiate() {
		return std::make_unique<AudioPlayerSGP>(_time);
	}
}
