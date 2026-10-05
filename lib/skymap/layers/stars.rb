# frozen_string_literal: true

module Skymap
  module Layers
    class Stars
      DEFAULT_MAGNITUDE_LIMIT = 5
      MAX_RADIUS_MAGNITUDE = -1.5
      MIN_STAR_RADIUS_RATIO = 0.0025
      MAX_STAR_RADIUS_RATIO = 0.02
      STAR_SIZE_EXPONENT = 1.5

      def initialize(stars:, magnitude_limit: DEFAULT_MAGNITUDE_LIMIT)
        @stars = stars
        @magnitude_limit = magnitude_limit
      end

      def elements(context)
        star_size = StarSize.new(
          brightest_magnitude: MAX_RADIUS_MAGNITUDE,
          faintest_magnitude: @magnitude_limit,
          min_radius: MIN_STAR_RADIUS_RATIO * context.canvas.radius,
          max_radius: MAX_STAR_RADIUS_RATIO * context.canvas.radius,
          exponent: STAR_SIZE_EXPONENT
        )

        @stars.filter_map do |star|
          next if star.magnitude > @magnitude_limit

          next if context.horizontal(star).altitude.negative?

          Renderer::Dot.new(
            center: context.position(star),
            radius: star_size.radius(star.magnitude)
          )
        end
      end
    end
  end
end
