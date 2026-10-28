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
      BOUNDARY_COLOR = "#2b3f5e"
      BOUNDARY_DASH_RATIO = 4
      ECLIPTIC_COLOR = "#8c7a3a"
      PLANET_COLOR = "#ffe6b3"
      SUN_COLOR = "#ffd34d"
      MOON_COLOR = "#f1ecd6"
      MOON_SHADOW_COLOR = "#232a35"
      MOON_SHADOW_OPACITY = 0.6
      CAPTION_COLORS = {constellation: "#6f8fc2", planet: PLANET_COLOR}
      LABEL_COLOR = HORIZON_COLOR
      LABEL_FONT = "sans-serif"

      def initialize(canvas:)
        @canvas = canvas
      end

      def render(elements)
        svg = Victor::SVG.new(
          viewBox: "0 0 #{@canvas.size} #{@canvas.size}",
          width: @canvas.size,
          height: @canvas.size
        )

        svg.circle(
          cx: @canvas.center.x.round(2),
          cy: @canvas.center.y.round(2),
          r: @canvas.radius.round(2),
          fill: SKY_COLOR,
          stroke: HORIZON_COLOR,
          stroke_width: HORIZON_WIDTH
        )

        elements.each do |element|
          case element
          when Boundary then draw_boundary(svg, element)
          when Caption then draw_caption(svg, element)
          when Line then draw_line(svg, element)
          when Dot then draw_dot(svg, element)
          when Ecliptic then draw_ecliptic(svg, element)
          when Label then draw_label(svg, element)
          when Moon then draw_moon(svg, element)
          when Planet then draw_planet(svg, element)
          when Sun then draw_sun(svg, element)
          else raise ArgumentError, "unknown element: #{element.class}"
          end
        end

        svg.render
      end

      private

      def draw_line(svg, line)
        svg.line(
          x1: line.from.x.round(2),
          y1: line.from.y.round(2),
          x2: line.to.x.round(2),
          y2: line.to.y.round(2),
          stroke: LINE_COLOR,
          stroke_width: line.width.round(2),
          stroke_linecap: "round"
        )
      end

      def draw_boundary(svg, boundary)
        dash = (boundary.width * BOUNDARY_DASH_RATIO).round(2)

        svg.polyline(
          points: boundary.points.map { |point|
            "#{point.x.round(2)},#{point.y.round(2)}"
          }.join(" "),
          fill: "none",
          stroke: BOUNDARY_COLOR,
          stroke_width: boundary.width.round(2),
          stroke_dasharray: "#{dash} #{dash}"
        )
      end

      def draw_ecliptic(svg, ecliptic)
        svg.polyline(
          points: ecliptic.points.map { |point|
            "#{point.x.round(2)},#{point.y.round(2)}"
          }.join(" "),
          fill: "none",
          stroke: ECLIPTIC_COLOR,
          stroke_width: ecliptic.width.round(2),
          stroke_linejoin: "round"
        )
      end

      def draw_dot(svg, dot)
        svg.circle(
          cx: dot.center.x.round(2),
          cy: dot.center.y.round(2),
          r: dot.radius.round(2),
          fill: STAR_COLOR
        )
      end

      def draw_planet(svg, planet)
        svg.circle(
          cx: planet.center.x.round(2),
          cy: planet.center.y.round(2),
          r: planet.radius.round(2),
          fill: PLANET_COLOR
        )
      end

      def draw_sun(svg, sun)
        svg.circle(
          cx: sun.center.x.round(2),
          cy: sun.center.y.round(2),
          r: sun.radius.round(2),
          fill: SUN_COLOR
        )
      end

      def draw_moon(svg, moon)
        x = moon.center.x.round(2)
        y = moon.center.y.round(2)
        radius = moon.radius.round(2)
        fraction = moon.illuminated_fraction
        terminator = (radius * (1 - 2 * fraction).abs).round(2)
        bulge = (fraction > 0.5) ? 1 : 0
        top = "#{x},#{(y - radius).round(2)}"
        bottom = "#{x},#{(y + radius).round(2)}"
        lit = "M #{top} A #{radius},#{radius} 0 0 1 #{bottom} " \
          "A #{terminator},#{radius} 0 0 #{bulge} #{top} Z"

        svg.build do
          g(transform: "rotate(#{moon.rotation.round(2)} #{x} #{y})") do
            circle(
              cx: x,
              cy: y,
              r: radius,
              fill: MOON_SHADOW_COLOR,
              fill_opacity: MOON_SHADOW_OPACITY
            )
            path(d: lit, fill: MOON_COLOR)
          end
        end
      end

      def draw_label(svg, label)
        draw_text(svg, label, LABEL_COLOR)
      end

      def draw_caption(svg, caption)
        draw_text(svg, caption, CAPTION_COLORS.fetch(caption.kind))
      end

      def draw_text(svg, label, fill)
        svg.text(
          label.text,
          x: label.position.x.round(2),
          y: label.position.y.round(2),
          font_size: label.size.round(2),
          font_family: LABEL_FONT,
          text_anchor: "middle",
          dominant_baseline: "central",
          fill: fill
        )
      end
    end
  end
end
