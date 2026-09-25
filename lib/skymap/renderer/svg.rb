# frozen_string_literal: true

require "victor"

module Skymap
  module Renderer
    class SVG
      SKY_COLOR = "#000000"
      HORIZON_COLOR = "#3262a8"
      HORIZON_WIDTH = 3
      STAR_COLOR = "#ffffff"
      STAR_RADIUS = 1

      def initialize(canvas:)
        @canvas = canvas
      end

      def render(points)
        svg = Victor::SVG.new(
          viewBox: "0 0 #{@canvas.size} #{@canvas.size}",
          width: @canvas.size,
          height: @canvas.size
        )

        svg.circle(
          cx: @canvas.center_x.round(2),
          cy: @canvas.center_y.round(2),
          r: @canvas.radius.round(2),
          fill: SKY_COLOR,
          stroke: HORIZON_COLOR,
          stroke_width: HORIZON_WIDTH
        )

        points.each do |x, y|
          svg.circle(
            cx: x.round(2),
            cy: y.round(2),
            r: STAR_RADIUS,
            fill: STAR_COLOR
          )
        end

        svg.render
      end
    end
  end
end
