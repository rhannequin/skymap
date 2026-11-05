# frozen_string_literal: true

module Skymap
  module Layers
    class Moon
      MOON_RADIUS_RATIO = 0.03
      LIT_SIDE_STEP = 1e-3
      NORTH = [1.0, 0.0, 0.0].freeze
      ZENITH = [0.0, 0.0, 1.0].freeze

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
            rotation: rotation(moon, horizontal, center, context)
          )
        ]
      end

      private

      def rotation(moon, horizontal, center, context)
        from_zenith = Astronoby::Angle.from_radians(
          moon.bright_limb_position_angle.radians -
            moon.parallactic_angle(observer: context.observer).radians
        )
        lit_side = toward_lit_side(horizontal, from_zenith)
        lit_point = context.project(
          altitude: Astronoby::Angle.from_radians(
            Math.asin(lit_side[2].clamp(-1, 1))
          ),
          azimuth: Astronoby::Angle.from_radians(
            Math.atan2(lit_side[1], lit_side[0])
          )
        )

        Math.atan2(lit_point.y - center.y, lit_point.x - center.x) *
          180 / Math::PI
      end

      def toward_lit_side(horizontal, from_zenith)
        altitude = horizontal.altitude
        azimuth = horizontal.azimuth
        moon = [
          altitude.cos * azimuth.cos,
          altitude.cos * azimuth.sin,
          altitude.sin
        ]
        up = away_from(ZENITH, moon) || away_from(NORTH, moon)
        east = [azimuth.sin, -azimuth.cos, 0.0]
        sideways = away_from(east, moon)

        moon.each_index.map do |axis|
          moon[axis] + LIT_SIDE_STEP * (
            from_zenith.cos * up[axis] + from_zenith.sin * sideways[axis]
          )
        end
      end

      def away_from(reference, moon)
        along = reference.zip(moon).sum { |r, m| r * m }
        away = reference.zip(moon).map { |r, m| r - along * m }
        length = Math.sqrt(away.sum { |component| component * component })
        return if length < 1e-9

        away.map { |component| component / length }
      end
    end
  end
end
