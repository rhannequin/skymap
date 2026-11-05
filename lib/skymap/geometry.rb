# frozen_string_literal: true

module Skymap
  module Geometry
    module_function

    def dot(a, b)
      a.zip(b).sum { |x, y| x * y }
    end

    def cross(a, b)
      [
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0]
      ]
    end

    def normalize(vector)
      length = Math.sqrt(dot(vector, vector))

      vector.map { |component| component / length }
    end

    def away_from(reference, forward)
      along = dot(reference, forward)

      reference.zip(forward).map { |r, f| r - along * f }
    end

    def frame(forward)
      axis = (0..2).min_by { |index| forward[index].abs }
      reference = Array.new(3) { |index| (index == axis) ? 1.0 : 0.0 }
      up = normalize(away_from(reference, forward))

      [forward, cross(up, forward), up]
    end
  end
end
