# frozen_string_literal: true

module Skymap
  Star = Data.define(
    :hr,
    :equatorial_coordinates,
    :magnitude,
    :proper_motion_ra,
    :proper_motion_dec,
    :parallax,
    :radial_velocity
  ) do
    def self.by_hr(stars)
      stars.to_h { |star| [star.hr, star] }
    end

    def initialize(
      hr:,
      equatorial_coordinates:,
      magnitude:,
      proper_motion_ra: nil,
      proper_motion_dec: nil,
      parallax: nil,
      radial_velocity: nil
    )
      unless proper_motion?(proper_motion_ra)
        raise ArgumentError,
          "proper_motion_ra must be an Astronoby::AngularVelocity or nil"
      end

      unless proper_motion?(proper_motion_dec)
        raise ArgumentError,
          "proper_motion_dec must be an Astronoby::AngularVelocity or nil"
      end

      if proper_motion_ra.nil? != proper_motion_dec.nil?
        raise ArgumentError,
          "proper_motion_ra and proper_motion_dec must be given together"
      end

      unless parallax?(parallax)
        raise ArgumentError,
          "parallax must be an Astronoby::Angle above 0 or nil"
      end

      unless radial_velocity?(radial_velocity)
        raise ArgumentError,
          "radial_velocity must be an Astronoby::Velocity or nil"
      end

      super
    end

    def coordinates_at(instant)
      unless instant.is_a?(Astronoby::Instant)
        raise ArgumentError, "instant must be an Astronoby::Instant"
      end

      return equatorial_coordinates if proper_motion_ra.nil?

      propagated = Astronoby::StellarPropagation.equatorial_coordinates_for(
        instant: instant,
        equatorial_coordinates: equatorial_coordinates,
        proper_motion_ra: proper_motion_ra,
        proper_motion_dec: proper_motion_dec,
        parallax: parallax || Star::PLACEHOLDER_PARALLAX,
        radial_velocity: radial_velocity || Star::PLACEHOLDER_RADIAL_VELOCITY
      )

      Astronoby::Coordinates::Equatorial.new(
        right_ascension: propagated.right_ascension,
        declination: propagated.declination,
        epoch: Astronoby::JulianDate::J2000
      )
    end

    private

    def proper_motion?(value)
      value.nil? ||
        (value.is_a?(Astronoby::AngularVelocity) &&
          value.radians_per_second.finite?)
    end

    def parallax?(value)
      value.nil? ||
        (value.is_a?(Astronoby::Angle) &&
          value.radians.finite? && value.positive?)
    end

    def radial_velocity?(value)
      value.nil? ||
        (value.is_a?(Astronoby::Velocity) &&
          value.meters_per_second.finite?)
    end
  end

  Star::PLACEHOLDER_PARALLAX = Astronoby::Angle.from_degree_arcseconds(0.001)
  Star::PLACEHOLDER_RADIAL_VELOCITY =
    Astronoby::Velocity.from_kilometers_per_second(0)
end
