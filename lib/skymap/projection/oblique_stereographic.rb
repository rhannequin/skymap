# frozen_string_literal: true

module Skymap
  module Projection
    class ObliqueStereographic
      MIN_DENOMINATOR = 1e-9

      def initialize(center:, radius:, altitude:, azimuth:, field_of_view:)
        @center = center
        @forward = vector(altitude, azimuth)
        @up = Vector.up_from(
          @forward,
          Astronoby::Angle.from_degrees(field_of_view / 2.0).cos
        )
        @right = Vector.cross(@up, @forward)
        half_angle = Astronoby::Angle.from_degrees(field_of_view / 4.0)
        @scale = radius / (2 * half_angle.tan)
      end

      def project(altitude:, azimuth:)
        point = vector(altitude, azimuth)
        factor = 2 / [1 + Vector.dot(point, @forward), MIN_DENOMINATOR].max

        Point.new(
          x: @center.x + @scale * factor * Vector.dot(point, @right),
          y: @center.y - @scale * factor * Vector.dot(point, @up)
        )
      end

      def scale_at(altitude:, azimuth:)
        point = vector(altitude, azimuth)

        @scale * 2 / [1 + Vector.dot(point, @forward), MIN_DENOMINATOR].max
      end

      private

      def vector(altitude, azimuth)
        [
          altitude.cos * azimuth.cos,
          altitude.cos * azimuth.sin,
          altitude.sin
        ]
      end
    end
  end
end
