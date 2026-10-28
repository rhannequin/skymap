# frozen_string_literal: true

module Skymap
  Canvas = Data.define(:size, :padding) do
    def initialize(size:, padding:)
      unless padding >= 0 && padding < size / 2.0
        raise ArgumentError,
          "padding must not be negative and must be less than half the size"
      end

      super
    end

    def center
      Point.new(x: size / 2.0, y: size / 2.0)
    end

    def radius
      size / 2.0 - padding
    end
  end
end
