#ifndef SUPER_HAXAGON_FONT_SGP_HPP
#define SUPER_HAXAGON_FONT_SGP_HPP

#include "Core/Font.hpp"

#include <memory>

namespace SuperHaxagon {
	class Platform;
	class FontSGP : public Font {
	public:
		explicit FontSGP(int size);
		~FontSGP() override;

		void setScale(float) override;
		float getHeight() const override;
		float getWidth(const std::string& text) const override;
		void draw(const Color& color, const Vec2f& position, Alignment alignment, const std::string& text) override;

	private:
		int _size;
	};
}

#endif //SUPER_HAXAGON_FONT_SGP_HPP
