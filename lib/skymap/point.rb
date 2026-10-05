# frozen_string_literal: true

module Skymap
  Point = Data.define(:x, :y) do
    def self.midpoint(points)
      new(
        x: points.sum(&:x).fdiv(points.size),
        y: points.sum(&:y).fdiv(points.size)
      )
    end
  end
end
