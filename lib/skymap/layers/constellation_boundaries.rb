# frozen_string_literal: true

module Skymap
  module Layers
    class ConstellationBoundaries
      LINE_WIDTH_RATIO = 0.0017

      def initialize(boundaries:)
        @boundaries = boundaries
      end

      def elements(context)
        width = LINE_WIDTH_RATIO * context.canvas.radius

        @boundaries.flat_map do |boundary|
          Horizon.visible_runs(context, boundary.points).map do |points|
            Renderer::Boundary.new(points: points, width: width)
          end
        end
      end
    end
  end
end
