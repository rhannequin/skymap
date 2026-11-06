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

        candidates = StarList.wrap(@stars).search(
          magnitude_limit: @magnitude_limit,
          cone: context.cone
        )

        dots = candidates.filter_map do |star|
          dot = dot_for(star, context, star_size)
          [star.magnitude, dot] if dot
        end

        faintest_first(dots)
      end

      private

      def dot_for(star, context, star_size)
        radius = star_size.radius(star.magnitude)
        return unless context.possibly_visible?(star, radius)

        return if context.horizontal(star).altitude.negative?

        center = context.position(star)
        return unless context.in_view?(center, radius)

        Renderer::Dot.new(center: center, radius: radius)
      end

      def faintest_first(dots)
        dots.each_with_index
          .sort_by { |(magnitude, _), index| [-magnitude, index] }
          .map { |(_, dot), _| dot }
      end
    end
  end
end
