# frozen_string_literal: true

module Skymap
  class StarSize
    def initialize(
      brightest_magnitude:,
      faintest_magnitude:,
      min_radius:,
      max_radius:
    )
      @brightest_magnitude = brightest_magnitude
      @faintest_magnitude = faintest_magnitude
      @min_radius = min_radius
      @max_radius = max_radius
    end

    def radius(magnitude)
      brightness = (@faintest_magnitude - magnitude)
        .fdiv(@faintest_magnitude - @brightest_magnitude)

      @min_radius + brightness.clamp(0, 1) * (@max_radius - @min_radius)
    end
  end
end
