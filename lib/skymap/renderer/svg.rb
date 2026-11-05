# frozen_string_literal: true

require "victor"

module Skymap
  module Renderer
    class SVG
      HORIZON_WIDTH = 3
      FRAME_WIDTH = 1
      BOUNDARY_DASH_RATIO = 4

      def initialize(canvas:, theme:, clipped: false)
        @canvas = canvas
        @theme = theme
        @clipped = clipped
      end

      def render(elements)
        printed_size = (@canvas.print_size || @canvas.size).to_s
        svg = Victor::SVG.new(
          viewBox: "0 0 #{@canvas.size} #{@canvas.size}",
          width: printed_size,
          height: printed_size
        )

        draw_background(svg)

        svg.circle(
          cx: @canvas.center.x.round(2),
          cy: @canvas.center.y.round(2),
          r: @canvas.radius.round(2),
          fill: @theme.sky,
          stroke: @theme.horizon,
          stroke_width: @clipped ? FRAME_WIDTH : HORIZON_WIDTH
        )

        if @clipped
          clip_to_sky(svg)
          svg.g(clip_path: "url(##{clip_id})") { draw_elements(svg, elements) }
        else
          draw_elements(svg, elements)
        end

        svg.render
      end

      private

      def clip_to_sky(svg)
        radius = @canvas.radius.round(2)
        cx = @canvas.center.x.round(2)
        cy = @canvas.center.y.round(2)

        svg.defs do
          svg.clipPath(id: clip_id) { svg.circle(cx: cx, cy: cy, r: radius) }
        end
      end

      def clip_id
        geometry = [@canvas.center.x, @canvas.center.y, @canvas.radius]
          .map { |value| value.round(2).to_s.tr(".", "_") }

        "sky-#{geometry.join("-")}"
      end

      def draw_elements(svg, elements)
        elements.each do |element|
          case element
          when Boundary then draw_boundary(svg, element)
          when Caption then draw_caption(svg, element)
          when Line then draw_line(svg, element)
          when ScaleBar then draw_scale_bar(svg, element)
          when Dot then draw_dot(svg, element)
          when Ecliptic then draw_ecliptic(svg, element)
          when FieldCircle then draw_field_circle(svg, element)
          when Grid then draw_grid(svg, element)
          when HorizonLine then draw_horizon_line(svg, element)
          when Label then draw_label(svg, element)
          when Moon then draw_moon(svg, element)
          when Planet then draw_planet(svg, element)
          when Sun then draw_sun(svg, element)
          else raise ArgumentError, "unknown element: #{element.class}"
          end
        end
      end

      def format_points(points)
        points.map { |point| "#{point.x.round(2)},#{point.y.round(2)}" }
          .join(" ")
      end

      def draw_background(svg)
        return if @theme.background == "none"

        svg.rect(
          x: 0,
          y: 0,
          width: @canvas.size,
          height: @canvas.size,
          fill: @theme.background
        )
      end

      def draw_line(svg, line)
        svg.line(
          x1: line.from.x.round(2),
          y1: line.from.y.round(2),
          x2: line.to.x.round(2),
          y2: line.to.y.round(2),
          stroke: @theme.constellation_line,
          stroke_width: line.width.round(2),
          stroke_linecap: "round"
        )
      end

      def draw_scale_bar(svg, bar)
        top = bar.from.y - bar.tick
        points = [
          Point.new(x: bar.from.x, y: top), bar.from,
          bar.to, Point.new(x: bar.to.x, y: top)
        ]

        svg.polyline(
          points: format_points(points),
          fill: "none",
          stroke: @theme.scale,
          stroke_width: bar.width.round(2)
        )
      end

      def draw_boundary(svg, boundary)
        dash = (boundary.width * BOUNDARY_DASH_RATIO).round(2)

        svg.polyline(
          points: format_points(boundary.points),
          fill: "none",
          stroke: @theme.boundary,
          stroke_width: boundary.width.round(2),
          stroke_dasharray: "#{dash} #{dash}"
        )
      end

      def draw_ecliptic(svg, ecliptic)
        draw_polyline(svg, ecliptic, @theme.ecliptic)
      end

      def draw_field_circle(svg, circle)
        draw_polyline(svg, circle, @theme.field_circle)
      end

      def draw_grid(svg, grid)
        draw_polyline(svg, grid, @theme.grid)
      end

      def draw_polyline(svg, element, stroke)
        svg.polyline(
          points: format_points(element.points),
          fill: "none",
          stroke: stroke,
          stroke_width: element.width.round(2),
          stroke_linejoin: "round"
        )
      end

      def draw_horizon_line(svg, line)
        svg.polyline(
          points: format_points(line.points),
          fill: "none",
          stroke: @theme.horizon,
          stroke_width: HORIZON_WIDTH,
          stroke_linejoin: "round"
        )
      end

      def draw_dot(svg, dot)
        svg.circle(
          cx: dot.center.x.round(2),
          cy: dot.center.y.round(2),
          r: dot.radius.round(2),
          fill: @theme.star
        )
      end

      def draw_planet(svg, planet)
        svg.circle(
          cx: planet.center.x.round(2),
          cy: planet.center.y.round(2),
          r: planet.radius.round(2),
          fill: @theme.planet
        )
      end

      def draw_sun(svg, sun)
        svg.circle(
          cx: sun.center.x.round(2),
          cy: sun.center.y.round(2),
          r: sun.radius.round(2),
          fill: @theme.sun
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

        theme = @theme
        svg.build do
          g(transform: "rotate(#{moon.rotation.round(2)} #{x} #{y})") do
            circle(
              cx: x,
              cy: y,
              r: radius,
              fill: theme.moon_shadow,
              fill_opacity: theme.moon_shadow_opacity.to_f
            )
            path(d: lit, fill: theme.moon)
          end
        end
      end

      def draw_label(svg, label)
        draw_text(svg, label, @theme.label)
      end

      def draw_caption(svg, caption)
        draw_text(svg, caption, caption_color(caption.kind))
      end

      def caption_color(kind)
        case kind
        when :constellation then @theme.constellation_name
        when :star then @theme.star_name
        when :planet then @theme.planet_name
        when :field then @theme.field_circle
        when :scale then @theme.scale
        else raise ArgumentError, "unknown caption kind: #{kind}"
        end
      end

      def draw_text(svg, label, fill)
        svg.text(
          label.text,
          x: label.position.x.round(2),
          y: label.position.y.round(2),
          font_size: label.size.round(2),
          font_family: @theme.font,
          text_anchor: "middle",
          dominant_baseline: "central",
          fill: fill
        )
      end
    end
  end
end
