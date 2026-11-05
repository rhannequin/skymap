# frozen_string_literal: true

module Skymap
  module Projection
    class ObliqueStereographic
      MIN_DENOMINATOR = 1e-9
      NORTH = [1.0, 0.0, 0.0].freeze
      ZENITH = [0.0, 0.0, 1.0].freeze

      def initialize(center:, radius:, altitude:, azimuth:, field_of_view:)
        @center = center
        @forward = vector(altitude, azimuth)
        @up = up_from(@forward, field_of_view)
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

      private

      def vector(altitude, azimuth)
        [
          altitude.cos * azimuth.cos,
          altitude.cos * azimuth.sin,
          altitude.sin
        ]
      end

      def up_from(forward, field_of_view)
        half_angle = Astronoby::Angle.from_degrees(field_of_view / 2.0)
        references = [ZENITH, NORTH]
        references.reverse! if forward[2] >= half_angle.cos

        references.each do |reference|
          up = away_from(reference, forward)
          length = Math.sqrt(dot(up, up))
          return up.map { |component| component / length } if length > 1e-9
        end
      end

      def away_from(reference, forward)
        along = dot(reference, forward)

        reference.zip(forward).map { |r, f| r - along * f }
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
