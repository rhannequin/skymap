# frozen_string_literal: true

module Skymap
  module Horizon
    module_function

    def direction(horizontals)
      vectors = horizontals.map do |horizontal|
        [
          horizontal.altitude.cos * horizontal.azimuth.cos,
          horizontal.altitude.cos * horizontal.azimuth.sin,
          horizontal.altitude.sin
        ]
      end
      vectors.transpose.map(&:sum)
    end

    def crossing(above, below)
      above.zip(below).map do |from, to|
        above.last * to - below.last * from
      end
    end

    def project(context, direction)
      x, y, = direction
      context.project(
        altitude: Astronoby::Angle.zero,
        azimuth: Astronoby::Angle.from_radians(Math.atan2(y, x))
      )
    end
  end
end
