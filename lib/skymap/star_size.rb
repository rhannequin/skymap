# frozen_string_literal: true

module Skymap
  class StarSize
    MAX_RADIUS_MAGNITUDE = -1.5
    MIN_RADIUS_RATIO = 0.0025
    MAX_RADIUS_RATIO = 0.02
    EXPONENT = 1.5

    def self.for(canvas:, magnitude_limit:)
      new(
        brightest_magnitude: MAX_RADIUS_MAGNITUDE,
        faintest_magnitude: magnitude_limit,
        min_radius: MIN_RADIUS_RATIO * canvas.radius,
        max_radius: MAX_RADIUS_RATIO * canvas.radius,
        exponent: EXPONENT
      )
    end

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
