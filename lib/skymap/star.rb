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
      stars.filter_map { |star| [star.hr, star] if star.hr }.to_h
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
      unless hr?(hr)
        raise ArgumentError, "hr must be a positive Integer or nil"
      end

      unless equatorial_coordinates.is_a?(Astronoby::Coordinates::Equatorial)
        raise ArgumentError,
          "equatorial_coordinates must be Astronoby::Coordinates::Equatorial"
      end

      unless magnitude?(magnitude)
        raise ArgumentError, "magnitude must be a finite Numeric"
      end

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

      if proper_motion_ra &&
          equatorial_coordinates.epoch != Astronoby::JulianDate::J2000
        raise ArgumentError,
          "equatorial_coordinates must be at J2000 when a proper motion " \
          "is given, as it is applied from J2000"
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
        parallax: parallax || placeholder_parallax,
        radial_velocity: radial_velocity || placeholder_radial_velocity
      )

      Astronoby::Coordinates::Equatorial.new(
        right_ascension: propagated.right_ascension,
        declination: propagated.declination,
        epoch: Astronoby::JulianDate::J2000
      )
    end

    placeholder_parallax = Astronoby::Angle.from_degree_arcseconds(0.001)
    placeholder_radial_velocity =
      Astronoby::Velocity.from_kilometers_per_second(0)

    private define_method(:placeholder_parallax) { placeholder_parallax }
    private define_method(:placeholder_radial_velocity) {
      placeholder_radial_velocity
    }

    private

    def hr?(value)
      value.nil? || (value.is_a?(Integer) && value.positive?)
    end

    def magnitude?(value)
      value.is_a?(Numeric) && value.real? && value.finite?
    end

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
end
