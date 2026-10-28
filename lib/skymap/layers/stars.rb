# frozen_string_literal: true

module Skymap
  module Layers
    class Stars
      DEFAULT_MAGNITUDE_LIMIT = 5

      def initialize(stars:, magnitude_limit: DEFAULT_MAGNITUDE_LIMIT)
        @stars = stars
        @magnitude_limit = magnitude_limit
      end

      def elements(context)
        star_size = StarSize.for(
          canvas: context.canvas,
          magnitude_limit: @magnitude_limit
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
