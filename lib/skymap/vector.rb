# frozen_string_literal: true

module Skymap
  module Vector
    NORTH = [1.0, 0.0, 0.0].freeze
    ZENITH = [0.0, 0.0, 1.0].freeze

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

    def up_from(forward, zenith_cosine)
      references = [ZENITH, NORTH]
      references.reverse! if forward[2] >= zenith_cosine

      references.each do |reference|
        up = away_from(reference, forward)
        return normalize(up) if Math.sqrt(dot(up, up)) > 1e-9
      end
    end
  end
end
