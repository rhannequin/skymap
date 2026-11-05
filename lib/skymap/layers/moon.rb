# frozen_string_literal: true

module Skymap
  module Layers
    class Moon
      MOON_RADIUS_RATIO = 0.03

      def initialize(ephem:)
        @ephem = ephem
      end

      def elements(context)
        moon = Astronoby::Moon.at(context.instant, ephem: @ephem)
        horizontal = moon.observed_by(context.observer).horizontal
        return [] if horizontal.altitude.negative?

        center = context.project(
          altitude: horizontal.altitude,
          azimuth: horizontal.azimuth
        )
        radius = [
          MOON_RADIUS_RATIO * context.canvas.radius,
          context.span(
            moon.angular_diameter,
            altitude: horizontal.altitude,
            azimuth: horizontal.azimuth
          ) / 2
        ].max
        return [] unless context.in_view?(center, radius)

        [
          Renderer::Moon.new(
            center: center,
            radius: radius,
            illuminated_fraction: moon.illuminated_fraction,
            rotation: rotation(moon, context.observer)
          )
        ]
      end

      private

      def rotation(moon, observer)
        from_zenith = moon.bright_limb_position_angle.degrees -
          moon.parallactic_angle(observer: observer).degrees

        -90 - from_zenith
      end
    end
  end
end
