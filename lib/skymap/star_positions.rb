# frozen_string_literal: true

module Skymap
  class StarPositions
    TOLERANCE = 0.005
    SHIFT_SLACK = 1e-6
    PROPER_MOTION_ROUNDING = 1e-15
    PRECESSION_ARCSECONDS_PER_YEAR = 50.3
    FASTEST_PROPER_MOTION_ARCSECONDS_PER_YEAR = 10.4
    NUTATION_AND_ABERRATION_ARCSECONDS = 60.0
    private_constant :TOLERANCE, :SHIFT_SLACK, :PROPER_MOTION_ROUNDING,
      :PRECESSION_ARCSECONDS_PER_YEAR,
      :FASTEST_PROPER_MOTION_ARCSECONDS_PER_YEAR,
      :NUTATION_AND_ABERRATION_ARCSECONDS

    def initialize(instant:, convert:, scale:)
      @instant = instant
      @convert = convert
      @scale = scale
      @horizontals = {}.compare_by_identity
      @catalog_horizontals = {}.compare_by_identity
      @shifts = {}.compare_by_identity
    end

    def horizontal(star)
      @horizontals[star] ||= star_horizontal(star)
    end

    def catalog_horizontal(star)
      @catalog_horizontals[star] ||= @convert.call(star.equatorial_coordinates)
    end

    def maximum_shift(star)
      shift(star) + SHIFT_SLACK
    end

    def drift
      arcseconds = elapsed_years * (
        PRECESSION_ARCSECONDS_PER_YEAR +
        FASTEST_PROPER_MOTION_ARCSECONDS_PER_YEAR
      ) + NUTATION_AND_ABERRATION_ARCSECONDS

      Astronoby::Angle.from_degree_arcseconds(arcseconds).radians
    end

    private

    def shift(star)
      @shifts[star] ||= compute_shift(star)
    end

    def star_horizontal(star)
      catalog = catalog_horizontal(star)
      shift = shift(star)
      return catalog if shift.zero?

      scale = @scale.call(altitude: catalog.altitude, azimuth: catalog.azimuth)
      return catalog if shift * scale < TOLERANCE

      @convert.call(star.coordinates_at(@instant))
    end

    def compute_shift(star)
      return 0.0 if star.proper_motion_ra.nil? || elapsed_years.zero?

      rate = Math.hypot(
        proper_motion_bound(star.proper_motion_ra),
        proper_motion_bound(star.proper_motion_dec)
      ) * Astronoby::Constants::SECONDS_PER_JULIAN_YEAR
      velocity = (star.radial_velocity&.meters_per_second || 0).abs.to_f
      seconds = elapsed_years * Astronoby::Constants::SECONDS_PER_JULIAN_YEAR
      parallax = star.parallax&.radians || 0
      slack = velocity / Astronoby::Constants::LIGHT_SPEED_M_PER_S +
        velocity * seconds * parallax /
          Astronoby::Constants::ASTRONOMICAL_UNIT_IN_METERS
      return Float::INFINITY if slack >= 0.5

      rate * elapsed_years / (1 - slack)
    end

    def proper_motion_bound(proper_motion)
      rate = proper_motion.radians_per_second

      rate.negative? ? -rate + PROPER_MOTION_ROUNDING : rate
    end

    def elapsed_years
      @elapsed_years ||= (@instant.tt - Astronoby::JulianDate::J2000).abs /
        Astronoby::Constants::DAYS_PER_JULIAN_YEAR
    end
  end
end
