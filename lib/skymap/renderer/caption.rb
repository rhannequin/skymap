# frozen_string_literal: true

module Skymap
  module Renderer
    CAPTION_SIZE_RATIO = 0.028
    CAPTION_CHARACTER_WIDTH_RATIO = 0.55

    module TextWidth
      def self.of(text, size)
        text.length * size * CAPTION_CHARACTER_WIDTH_RATIO
      end

      def width
        TextWidth.of(text, size)
      end
    end

    Caption = Data.define(
      :position,
      :text,
      :size,
      :kind,
      :anchor,
      :clearance
    ) do
      include TextWidth

      def initialize(
        position:,
        text:,
        size:,
        kind:,
        anchor: nil,
        clearance: 0.0
      )
        super
      end

      def self.size_for(canvas)
        CAPTION_SIZE_RATIO * canvas.radius
      end

      def self.beside(center:, radius:, canvas:, text:, kind:)
        size = size_for(canvas)
        towards_center = (center.y > canvas.center.y) ? -1 : 1
        y = center.y + towards_center * (radius + size)

        new(
          position: Point.new(
            x: within_sky(center.x, y, text, size, canvas),
            y: y
          ),
          text: text,
          size: size,
          kind: kind,
          anchor: center,
          clearance: radius
        )
      end

      def self.within_sky(x, y, text, size, canvas)
        dy = (y - canvas.center.y).abs + size / 2
        room = Math.sqrt([canvas.radius**2 - dy**2, 0].max)
        half_width = TextWidth.of(text, size) / 2
        reach = [room - half_width, 0].max

        canvas.center.x + (x - canvas.center.x).clamp(-reach, reach)
      end
      private_class_method :within_sky
    end
  end
end
