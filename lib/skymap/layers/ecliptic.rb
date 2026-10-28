# frozen_string_literal: true

module Skymap
  module Layers
    class Ecliptic
      LINE_WIDTH_RATIO = 0.0025
      STEP_IN_DEGREES = 1

      def initialize
        @points = (0..360).step(STEP_IN_DEGREES).map do |degrees|
          point_at(Astronoby::Angle.from_degrees(degrees))
        end
      end

      def elements(context)
        width = LINE_WIDTH_RATIO * context.canvas.radius

        Horizon.visible_runs(context, @points).map do |points|
          Renderer::Ecliptic.new(points: points, width: width)
        end
      end

      private

      def point_at(longitude)
        obliquity = Astronoby::MeanObliquity.obliquity_of_reference

        Astronoby::Coordinates::Equatorial.new(
          right_ascension: Astronoby::Angle.from_radians(
            Math.atan2(longitude.sin * obliquity.cos, longitude.cos)
          ),
          declination: Astronoby::Angle.asin(longitude.sin * obliquity.sin),
          epoch: Astronoby::JulianDate::J2000
        )
      end
    end
  end
end
