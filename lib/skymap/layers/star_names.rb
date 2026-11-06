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
        MagnitudeLimit.check(magnitude_limit, allow_nil: true)
        MagnitudeLimit.check(
          stars_magnitude_limit,
          name: :stars_magnitude_limit
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

        candidates = StarList.wrap(@stars).search(
          magnitude_limit: @magnitude_limit,
          cone: context.cone
        )

        candidates.filter_map do |star|
          next unless star.hr

          name = @names[star.hr]
          next unless name

          radius = star_size.radius(star.magnitude)
          next unless context.possibly_visible?(star, radius)

          next if context.horizontal(star).altitude.negative?

          center = context.position(star)
          next unless context.in_view?(center, radius)

          Renderer::Caption.beside(
            center: center,
            radius: radius,
            canvas: context.canvas,
            text: name,
            kind: :star
          )
        end
      end
    end
  end
end
