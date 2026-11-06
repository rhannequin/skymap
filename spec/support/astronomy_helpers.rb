# frozen_string_literal: true

module AstronomyHelpers
  def observer_at(latitude:)
    Astronoby::Observer.new(
      latitude: Astronoby::Angle.from_degrees(latitude),
      longitude: Astronoby::Angle.zero
    )
  end

  def context_at(latitude:, canvas:, view: nil)
    Skymap::Context.new(
      observer: observer_at(latitude: latitude),
      instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 22)),
      canvas: canvas,
      view: view
    )
  end

  def view_towards(altitude:, azimuth:, field_of_view:, latitude: 48.8575)
    Skymap::View.new(
      center: Astronoby::Coordinates::Horizontal.new(
        altitude: Astronoby::Angle.from_degrees(altitude),
        azimuth: Astronoby::Angle.from_degrees(azimuth),
        observer: observer_at(latitude: latitude)
      ),
      field_of_view: Astronoby::Angle.from_degrees(field_of_view)
    )
  end

  def ephemeris
    Astronoby::Ephem.load(
      File.expand_path(
        "../fixtures/de440s_2025_2030_excerpt.bsp",
        __dir__
      )
    )
  end

  def star(right_ascension:, declination:, magnitude:, hr: nil, **astrometry)
    Skymap::Star.new(
      hr: hr,
      equatorial_coordinates: Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_hours(right_ascension),
        declination: Astronoby::Angle.from_degrees(declination),
        epoch: Astronoby::JulianDate::J2000
      ),
      magnitude: magnitude,
      **astrometry
    )
  end

  def deep_sky_object(
    right_ascension: 21.0,
    declination: 31.5,
    designation: "M99",
    type: :galaxy,
    major: nil,
    minor: nil,
    position_angle: nil,
    **attributes
  )
    Skymap::DeepSkyObject.new(
      designation: designation,
      type: type,
      equatorial_coordinates: equatorial(
        right_ascension: right_ascension,
        declination: declination
      ),
      major_axis: major && Astronoby::Angle.from_degrees(major),
      minor_axis: minor && Astronoby::Angle.from_degrees(minor),
      position_angle: position_angle &&
        Astronoby::Angle.from_degrees(position_angle),
      **attributes
    )
  end

  def motion(proper_motion_ra:, proper_motion_dec:, parallax: nil,
    radial_velocity: nil)
    {
      proper_motion_ra: Astronoby::AngularVelocity
        .from_milliarcseconds_per_year(proper_motion_ra),
      proper_motion_dec: Astronoby::AngularVelocity
        .from_milliarcseconds_per_year(proper_motion_dec),
      parallax: parallax && Astronoby::Angle.from_degree_arcseconds(
        parallax / 1000.0
      ),
      radial_velocity: radial_velocity &&
        Astronoby::Velocity.from_kilometers_per_second(radial_velocity)
    }
  end

  def years_since_j2000(instant)
    (instant.tt - Astronoby::JulianDate::J2000) / 365.25
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
