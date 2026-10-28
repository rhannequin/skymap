# frozen_string_literal: true

module Skymap
  module Renderer
    CAPTION_SIZE_RATIO = 0.028

    Caption = Data.define(:position, :text, :size, :kind) do
      def self.size_for(canvas)
        CAPTION_SIZE_RATIO * canvas.radius
      end
    end
  end
end
