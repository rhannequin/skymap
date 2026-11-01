# frozen_string_literal: true

module Skymap
  module Renderer
    CAPTION_SIZE_RATIO = 0.028
    CAPTION_CHARACTER_WIDTH_RATIO = 0.55

    Caption = Data.define(:position, :text, :size, :kind) do
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
          kind: kind
        )
      end

      def self.within_sky(x, y, text, size, canvas)
        dy = (y - canvas.center.y).abs + size / 2
        room = Math.sqrt([canvas.radius**2 - dy**2, 0].max)
        half_width = text.length * size * CAPTION_CHARACTER_WIDTH_RATIO / 2
        reach = [room - half_width, 0].max

        canvas.center.x + (x - canvas.center.x).clamp(-reach, reach)
      end
      private_class_method :within_sky
    end
  end
end
