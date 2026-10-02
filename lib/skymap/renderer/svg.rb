# frozen_string_literal: true

require "victor"

module Skymap
  module Renderer
    class SVG
      SKY_COLOR = "#000000"
      HORIZON_COLOR = "#3262a8"
      HORIZON_WIDTH = 3
      STAR_COLOR = "#ffffff"
      LINE_COLOR = "#46689c"
      LABEL_COLOR = HORIZON_COLOR
      LABEL_FONT = "sans-serif"

      def initialize(canvas:)
        @canvas = canvas
      end

      def render(dots:, labels:, lines:)
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

        lines.each do |line|
          svg.line(
            x1: line.x1.round(2),
            y1: line.y1.round(2),
            x2: line.x2.round(2),
            y2: line.y2.round(2),
            stroke: LINE_COLOR,
            stroke_width: line.width.round(2),
            stroke_linecap: "round"
          )
        end

        dots.each do |dot|
          svg.circle(
            cx: dot.x.round(2),
            cy: dot.y.round(2),
            r: dot.radius.round(2),
            fill: STAR_COLOR
          )
        end

        labels.each do |label|
          svg.text(
            label.text,
            x: label.x.round(2),
            y: label.y.round(2),
            font_size: label.size.round(2),
            font_family: LABEL_FONT,
            text_anchor: "middle",
            dominant_baseline: "central",
            fill: LABEL_COLOR
          )
        end

        svg.render
      end
    end
  end
end
