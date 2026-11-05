# frozen_string_literal: true

module Skymap
  Canvas = Data.define(:size, :padding, :print_size) do
    def initialize(size:, padding:, print_size: nil)
      unless padding >= 0 && padding < size / 2.0
        raise ArgumentError,
          "padding must not be negative and must be less than half the size"
      end

      unless print_size.nil? || print_size.is_a?(PrintSize)
        raise ArgumentError, "print_size must be a Skymap::PrintSize"
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
