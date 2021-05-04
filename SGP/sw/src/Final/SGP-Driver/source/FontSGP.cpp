#include "FontSGP.hpp"

#include "Core/Structs.hpp"

namespace SuperHaxagon {
	FontSGP::FontSGP(const int size) : _size(size) {}

	FontSGP::~FontSGP() = default;

	float FontSGP::getWidth(const std::string& text) const {
		return static_cast<float>(_size * text.length());
	}

	void FontSGP::draw(const Color&, const Vec2f&, const Alignment alignment, const std::string& text) {}

	void FontSGP::setScale(float) {}

	float FontSGP::getHeight() const {
		return static_cast<float>(_size);
	}
}
