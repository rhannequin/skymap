# frozen_string_literal: true

module Skymap
  Canvas = Data.define(:size, :padding) do
    def center
      Point.new(x: size / 2.0, y: size / 2.0)
    end

    def radius
      size / 2.0 - padding
    end
  end
end
