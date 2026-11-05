# frozen_string_literal: true

module Skymap
  module Layers
    class Scale
      UNITS = [["″", 1 / 3600.0], ["′", 1 / 60.0], ["°", 1.0]].freeze
      STEPS = [1, 2, 5, 10, 20, 30].freeze
      MAX_LENGTH_RATIO = 0.2
      LINE_WIDTH_RATIO = 0.005
      TICK_SIZE_RATIO = 0.5
      LEFT_RATIO = -0.5
      BOTTOM_RATIO = 0.76
      LABEL_GAP_RATIO = 0.7

      def elements(context)
        return [] if context.full_sky?

        canvas = context.canvas
        max_length = MAX_LENGTH_RATIO * 2 * canvas.radius
        length, text = longest_fitting(context, max_length)
        return [] unless length

        size = Renderer::Caption.size_for(canvas)
        left = canvas.center.x + LEFT_RATIO * canvas.radius
        y = canvas.center.y + BOTTOM_RATIO * canvas.radius
        tick = TICK_SIZE_RATIO * size

        [
          Renderer::ScaleBar.new(
            from: Point.new(x: left, y: y),
            to: Point.new(x: left + length, y: y),
            tick: tick,
            width: LINE_WIDTH_RATIO * canvas.radius
          ),
          Renderer::Caption.new(
            position: Point.new(
              x: left + length / 2,
              y: y - tick - LABEL_GAP_RATIO * size
            ),
            text: text,
            size: size,
            kind: :scale
          )
        ]
      end

      private

      def longest_fitting(context, max_length)
        UNITS.product(STEPS).reverse_each do |(symbol, degrees), step|
          angle = Astronoby::Angle.from_degrees(step * degrees)
          length = context.view_span(angle)
          return [length, "#{step}#{symbol}"] if length <= max_length
        end

        nil
      end
    end
  end
end
