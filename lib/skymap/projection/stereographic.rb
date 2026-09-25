# frozen_string_literal: true

module Skymap
  module Projection
    class Stereographic
      def initialize(center_x:, center_y:, radius:)
        @center_x = center_x
        @center_y = center_y
        @radius = radius
      end

      def project(altitude:, azimuth:)
        distance = @radius * altitude.cos / (1 + altitude.sin)

        [
          @center_x - distance * azimuth.sin,
          @center_y - distance * azimuth.cos
        ]
      end
    end
  end
end
