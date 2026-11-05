# frozen_string_literal: true

module Skymap
  module Projection
    class ObliqueStereographic
      MIN_DENOMINATOR = 1e-9

      def initialize(center:, radius:, altitude:, azimuth:, field_of_view:)
        @center = center
        @forward = vector(altitude, azimuth)
        @up = up_from(@forward)
        @right = cross(@up, @forward)
        half_angle = Astronoby::Angle.from_degrees(field_of_view / 4.0)
        @scale = radius / (2 * half_angle.tan)
      end

      def project(altitude:, azimuth:)
        point = vector(altitude, azimuth)
        factor = 2 / [1 + dot(point, @forward), MIN_DENOMINATOR].max

        Point.new(
          x: @center.x + @scale * factor * dot(point, @right),
          y: @center.y - @scale * factor * dot(point, @up)
        )
      end

      def scale_at(altitude:, azimuth:)
        point = vector(altitude, azimuth)

        @scale * 2 / [1 + dot(point, @forward), MIN_DENOMINATOR].max
      end

      private

      def vector(altitude, azimuth)
        [
          altitude.cos * azimuth.cos,
          altitude.cos * azimuth.sin,
          altitude.sin
        ]
      end

      def up_from(forward)
        up = [-forward[0] * forward[2], -forward[1] * forward[2],
          1 - forward[2]**2]
        length = Math.sqrt(dot(up, up))
        return [1.0, 0.0, 0.0] if length < 1e-12

        up.map { |component| component / length }
      end

      def dot(a, b)
        a.zip(b).sum { |x, y| x * y }
      end

      def cross(a, b)
        [
          a[1] * b[2] - a[2] * b[1],
          a[2] * b[0] - a[0] * b[2],
          a[0] * b[1] - a[1] * b[0]
        ]
      end
    end
  end
end
