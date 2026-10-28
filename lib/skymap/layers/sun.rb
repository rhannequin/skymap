# frozen_string_literal: true

module Skymap
  module Layers
    class Sun
      SUN_RADIUS_RATIO = 0.03

      def initialize(ephem:)
        @ephem = ephem
      end

      def elements(context)
        sun = Astronoby::Sun.at(context.instant, ephem: @ephem)
        horizontal = sun.observed_by(context.observer).horizontal
        return [] if horizontal.altitude.negative?

        [
          Renderer::Sun.new(
            center: context.project(
              altitude: horizontal.altitude,
              azimuth: horizontal.azimuth
            ),
            radius: SUN_RADIUS_RATIO * context.canvas.radius
          )
        ]
      end
    end
  end
end
