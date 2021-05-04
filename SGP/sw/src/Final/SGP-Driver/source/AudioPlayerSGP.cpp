#include "AudioPlayerSGP.hpp"

namespace SuperHaxagon {
	AudioPlayerSGP::AudioPlayerSGP(const float maxTime) {
		_maxTime = maxTime;
	}

	void AudioPlayerSGP::play() {
		if (isDone()) {
			_time = 0.0f;
		}

		_playing = true;
	}

	void AudioPlayerSGP::pause() {
		_playing = false;
	}

	bool AudioPlayerSGP::isDone() const {
		return _time > _maxTime + 5.0f;
	}

	float AudioPlayerSGP::getTime() const {
		return _time;
	}

	void AudioPlayerSGP::addTime(const float time) {
		if (_playing) {
			_time += time;
		}
	}
}
