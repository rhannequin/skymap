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
        radius = context.disk_radius(
          MOON_RADIUS_RATIO * context.canvas.radius,
          angular_diameter: moon.angular_diameter,
          altitude: horizontal.altitude,
          azimuth: horizontal.azimuth
        )
        return [] unless context.in_view?(center, radius)

        [
          Renderer::Moon.new(
            center: center,
            radius: radius,
            illuminated_fraction: moon.illuminated_fraction,
            rotation: rotation(moon, context)
          )
        ]
      end

      private

      def rotation(moon, context)
        angle = moon.bright_limb_position_angle.degrees
        view = context.view
        unless view&.orientation == :equatorial
          angle -= moon.parallactic_angle(observer: context.observer).degrees
        end
        sense = view&.mirrored ? 1 : -1

        sense * angle + (view&.rotation || 0) - 90
      end
    end
  end
end
