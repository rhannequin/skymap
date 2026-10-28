# frozen_string_literal: true

module Skymap
  class Sky
    def initialize(observer:, instant:)
      @observer = observer
      @time = instant.to_time.utc
      @rotation = (
        Astronoby::Nutation.matrix_for(instant) *
        Astronoby::Precession.matrix_for(instant)
      ).to_a
      @sidereal_time = Astronoby::LocalApparentSiderealTime.from_utc(
        @time,
        longitude: observer.longitude
      ).time
    end

    def horizontal(coordinates)
      x, y, z = of_date(coordinates)
      right_ascension = Astronoby::Angle.from_radians(Math.atan2(y, x))
      hour_angle = (@sidereal_time - right_ascension.hours) %
        Astronoby::Constants::HOURS_PER_DAY

      Astronoby::Coordinates::Equatorial.new(
        right_ascension: right_ascension,
        declination: Astronoby::Angle.asin(z.clamp(-1, 1)),
        hour_angle: Astronoby::Angle.from_hours(hour_angle)
      ).to_horizontal(time: @time, observer: @observer)
    end

    private

    def of_date(coordinates)
      right_ascension = coordinates.right_ascension
      declination = coordinates.declination
      direction = [
        declination.cos * right_ascension.cos,
        declination.cos * right_ascension.sin,
        declination.sin
      ]

      @rotation.map { |row| row.zip(direction).sum { |a, b| a * b } }
    end
  end
end
