# frozen_string_literal: true

module Skymap
  module Projection
    class Stereographic
      def initialize(center:, radius:)
        @center = center
        @radius = radius
      end

      def project(altitude:, azimuth:)
        distance = @radius * altitude.cos / (1 + altitude.sin)

        Point.new(
          x: @center.x - distance * azimuth.sin,
          y: @center.y - distance * azimuth.cos
        )
      end

      def scale_at(altitude:, azimuth:)
        @radius / (1 + altitude.sin)
      end

      def scale_at_point(point)
        scale = @radius / 2.0
        distance = Math.hypot(point.x - @center.x, point.y - @center.y)

        scale * (1 + (distance / (2 * scale))**2)
      end
    end
  end
end
