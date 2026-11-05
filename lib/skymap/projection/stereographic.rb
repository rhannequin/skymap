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
    end
  end
end
