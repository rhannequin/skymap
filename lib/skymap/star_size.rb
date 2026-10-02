# frozen_string_literal: true

module Skymap
  class StarSize
    def initialize(
      brightest_magnitude:,
      faintest_magnitude:,
      min_radius:,
      max_radius:,
      exponent:
    )
      @brightest_magnitude = brightest_magnitude
      @faintest_magnitude = faintest_magnitude
      @min_radius = min_radius
      @max_radius = max_radius
      @exponent = exponent
    end

    def radius(magnitude)
      brightness = (@faintest_magnitude - magnitude)
        .fdiv(@faintest_magnitude - @brightest_magnitude)
        .clamp(0, 1)

      @min_radius + brightness**@exponent * (@max_radius - @min_radius)
    end
  end
end
