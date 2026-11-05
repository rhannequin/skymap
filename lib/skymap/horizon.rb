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

    def visible_runs(context, coordinates)
      horizontals = coordinates.map do |point|
        context.horizontal_coordinates(point)
      end
      path = [position(context, horizontals.first)] +
        horizontals.each_cons(2).flat_map do |from, to|
          crossing_point(context, from, to) + [position(context, to)]
        end

      runs_of(context, path)
    end

    def line(context)
      azimuths = (0...360).map do |degrees|
        Astronoby::Coordinates::Horizontal.new(
          altitude: Astronoby::Angle.zero,
          azimuth: Astronoby::Angle.from_degrees(degrees),
          observer: context.observer
        )
      end
      path = (azimuths + azimuths.first(1)).map do |horizontal|
        next unless context.reachable?(horizontal)

        context.project(
          altitude: horizontal.altitude,
          azimuth: horizontal.azimuth
        )
      end

      joined(runs_of(context, path))
    end

    def joined(runs)
      return runs unless runs.size > 1 && runs.first.first == runs.last.last

      [runs.last + runs.first.drop(1)] + runs[1...-1]
    end

    def runs_of(context, path)
      path.chunk { |point| !point.nil? }.filter_map do |visible, points|
        points if visible && points.size > 1 && context.crosses_view?(points)
      end
    end

    def position(context, horizontal)
      return if below?(horizontal) || !context.reachable?(horizontal)

      context.project(
        altitude: horizontal.altitude,
        azimuth: horizontal.azimuth
      )
    end

    def crossing_point(context, from, to)
      return [] if below?(from) == below?(to)

      above, below = below?(from) ? [to, from] : [from, to]
      [
        project(
          context,
          crossing(direction([above]), direction([below]))
        )
      ]
    end

    def below?(horizontal)
      horizontal.altitude.negative?
    end

    private_class_method :runs_of, :position, :crossing_point, :below?
  end
end
