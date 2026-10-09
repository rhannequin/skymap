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
          visible_runs(context, boundary.points).map do |points|
            Renderer::Boundary.new(points: points, width: width)
          end
        end
      end

      private

      def visible_runs(context, coordinates)
        horizontals = coordinates.map do |point|
          context.horizontal_coordinates(point)
        end
        path = [position(context, horizontals.first)] +
          horizontals.each_cons(2).flat_map do |from, to|
            crossing(context, from, to) + [position(context, to)]
          end

        path.chunk { |point| !point.nil? }.filter_map do |visible, points|
          points if visible && points.size > 1
        end
      end

      def position(context, horizontal)
        return if below?(horizontal)

        context.project(
          altitude: horizontal.altitude,
          azimuth: horizontal.azimuth
        )
      end

      def crossing(context, from, to)
        return [] if below?(from) == below?(to)

        above, below = below?(from) ? [to, from] : [from, to]
        [
          Horizon.project(
            context,
            Horizon.crossing(
              Horizon.direction([above]),
              Horizon.direction([below])
            )
          )
        ]
      end

      def below?(horizontal)
        horizontal.altitude.negative?
      end
    end
  end
end
