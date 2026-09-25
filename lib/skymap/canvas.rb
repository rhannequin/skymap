# frozen_string_literal: true

module Skymap
  Canvas = Data.define(:size, :padding) do
    def center_x
      size / 2.0
    end

    def center_y
      size / 2.0
    end

    def radius
      size / 2.0 - padding
    end
  end
end
