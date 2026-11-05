# frozen_string_literal: true

module Skymap
  module Projection
    class ObliqueStereographic
      MIN_DENOMINATOR = 1e-9
      NORTH = [1.0, 0.0, 0.0].freeze
      ZENITH = [0.0, 0.0, 1.0].freeze

      def initialize(
        center:,
        radius:,
        altitude:,
        azimuth:,
        field_of_view:,
        orientation: :zenith_up,
        pole: NORTH,
        rotation: Astronoby::Angle.zero,
        mirrored: false
      )
        @center = center
        @forward = vector(altitude, azimuth)
        up = up_from(@forward, field_of_view, orientation, pole)
        right = cross(up, @forward)
        right = right.map(&:-@) if mirrored
        @right, @up = turned(right, up, rotation)
        quarter = Astronoby::Angle.from_radians(field_of_view.radians / 4)
        @scale = radius / (2 * quarter.tan)
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

      def up_from(forward, field_of_view, orientation, pole)
        half_angle = Astronoby::Angle.from_radians(field_of_view.radians / 2)
        references = if orientation == :equatorial
          [pole, ZENITH, NORTH]
        elsif forward[2] >= half_angle.cos
          [NORTH, ZENITH]
        else
          [ZENITH, NORTH]
        end

        references.each do |reference|
          up = away_from(reference, forward)
          length = Math.sqrt(dot(up, up))
          return up.map { |component| component / length } if length > 1e-9
        end
      end

      def turned(right, up, rotation)
        [
          right.zip(up).map { |r, u| rotation.cos * r + rotation.sin * u },
          up.zip(right).map { |u, r| rotation.cos * u - rotation.sin * r }
        ]
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
