# frozen_string_literal: true

module Skymap
  module Layers
    class StarNames
      DEFAULT_MAGNITUDE_LIMIT = 2

      def initialize(
        stars:,
        magnitude_limit: DEFAULT_MAGNITUDE_LIMIT,
        stars_magnitude_limit: Stars::DEFAULT_MAGNITUDE_LIMIT,
        names: Catalog::StarNames.new
      )
        @stars = stars
        @magnitude_limit = magnitude_limit
        @stars_magnitude_limit = stars_magnitude_limit
        @names = names
      end

      def elements(context)
        star_size = StarSize.for(
          canvas: context.canvas,
          magnitude_limit: @stars_magnitude_limit
        )

        @stars.filter_map do |star|
          next if star.magnitude > @magnitude_limit

          name = @names[star.hr]
          next unless name

          next if context.horizontal(star).altitude.negative?

          Renderer::Caption.beside(
            center: context.position(star),
            radius: star_size.radius(star.magnitude),
            canvas: context.canvas,
            text: name,
            kind: :star
          )
        end
      end
    end
  end
end
