# frozen_string_literal: true

module AstronomyHelpers
  def observer_at(latitude:)
    Astronoby::Observer.new(
      latitude: Astronoby::Angle.from_degrees(latitude),
      longitude: Astronoby::Angle.zero
    )
  end

  def context_at(latitude:, canvas:)
    Skymap::Context.new(
      observer: observer_at(latitude: latitude),
      instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
      canvas: canvas
    )
  end

  def ephemeris
    Astronoby::Ephem.load(
      File.expand_path(
        "../fixtures/de440s_moon_2025_2030_excerpt.bsp",
        __dir__
      )
    )
  end

  def star(right_ascension:, declination:, magnitude:, hr: nil)
    Skymap::Star.new(
      hr: hr,
      equatorial_coordinates: Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_hours(right_ascension),
        declination: Astronoby::Angle.from_degrees(declination),
        epoch: Astronoby::JulianDate::J2000
      ),
      magnitude: magnitude
    )
  end

  def equatorial(right_ascension:, declination:)
    Astronoby::Coordinates::Equatorial.new(
      right_ascension: Astronoby::Angle.from_hours(right_ascension),
      declination: Astronoby::Angle.from_degrees(declination),
      epoch: Astronoby::JulianDate::J2000
    )
  end

  def constellation_boundary(points:)
    Skymap::ConstellationBoundary.new(
      constellations: %w[Cen Cru],
      points: points
    )
  end

  def constellation_line(from:, to:, weight: :normal)
    Skymap::ConstellationLine.new(
      constellation: "UMi",
      from: from,
      to: to,
      weight: weight
    )
  end
end

RSpec.configure do |config|
  config.include AstronomyHelpers
end
