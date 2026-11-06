# frozen_string_literal: true

module Skymap
  class Context
    MAX_ANGLE_FROM_VIEW_COSINE = Math.cos(150 * Math::PI / 180)
    STAR_POSITION_TOLERANCE = 0.005
    SHIFT_SLACK = 1e-6
    SECONDS_PER_JULIAN_YEAR = Astronoby::Constants::SECONDS_PER_JULIAN_YEAR
    ASTRONOMICAL_UNIT = 149_597_870_700.0
    SPEED_OF_LIGHT = 299_792_458.0
    PROPER_MOTION_ROUNDING = 1e-15
    POSITION_ANGLE_STEP = 1e-4
    private_constant :STAR_POSITION_TOLERANCE, :SHIFT_SLACK,
      :SECONDS_PER_JULIAN_YEAR, :ASTRONOMICAL_UNIT, :SPEED_OF_LIGHT,
      :PROPER_MOTION_ROUNDING, :POSITION_ANGLE_STEP

    attr_reader :observer, :instant, :canvas, :view

    def initialize(observer:, instant:, canvas:, view: nil)
      @observer = observer
      @instant = instant
      @canvas = canvas
      @view = view
      @transformation = Astronoby::HorizontalTransformation.new(
        observer: observer,
        instant: instant
      )
      @horizontal = {}
      @star_horizontals = {}.compare_by_identity
      @catalog_horizontals = {}.compare_by_identity
      @star_shifts = {}.compare_by_identity
      @projections = {}
    end

    def horizontal(star)
      @star_horizontals[star] ||= star_horizontal(star)
    end

    def possibly_visible?(star, margin = 0)
      catalog = catalog_horizontal(star)
      shift = star_shift(star) + SHIFT_SLACK
      return false if catalog.altitude.radians < -shift
      return true if full_sky?

      reach = view_reach(margin) + shift
      return true if reach >= Math::PI

      cosine_from_view(catalog) >= Math.cos(reach)
    end

    def horizontal_coordinates(coordinates)
      key = [
        coordinates.right_ascension,
        coordinates.declination,
        coordinates.epoch
      ]

      @horizontal[key] ||= convert(coordinates)
    end

    def to_horizontal(position)
      return position unless position.is_a?(Astronoby::Coordinates::Equatorial)

      horizontal_coordinates(position)
    end

    def position(star)
      horizontal = horizontal(star)
      project(altitude: horizontal.altitude, azimuth: horizontal.azimuth)
    end

    def project(altitude:, azimuth:, radius: @canvas.radius)
      projection(radius).project(altitude: altitude, azimuth: azimuth)
    end

    def span(angle, altitude:, azimuth:, radius: @canvas.radius)
      projection(radius).scale_at(altitude: altitude, azimuth: azimuth) *
        angle.radians
    end

    def rotation_at(coordinates, position_angle:)
      center = project_horizontal(horizontal_coordinates(coordinates))
      toward = project_horizontal(
        convert(step_toward(coordinates, position_angle))
      )

      Astronoby::Angle.from_radians(
        Math.atan2(toward.y - center.y, toward.x - center.x)
      )
    end

    def scale_at_point(point, radius: @canvas.radius)
      projection(radius).scale_at_point(point)
    end

    def disk_radius(default, angular_diameter:, altitude:, azimuth:)
      return default if full_sky?

      [
        default,
        span(angular_diameter, altitude: altitude, azimuth: azimuth) / 2
      ].max
    end

    def full_sky?
      @view.nil?
    end

    def in_view?(point, margin = 0)
      return true if full_sky?

      distance = Math.hypot(point.x - @canvas.center.x,
        point.y - @canvas.center.y)
      distance <= @canvas.radius + margin
    end

    def crosses_view?(points)
      return true if full_sky?

      return in_view?(points.first) if points.size == 1

      points.each_cons(2).any? do |from, to|
        distance_to_segment(@canvas.center, from, to) <= @canvas.radius
      end
    end

    def reachable?(horizontal)
      return true if full_sky?

      cosine_from_view(horizontal) > MAX_ANGLE_FROM_VIEW_COSINE
    end

    private

    def project_horizontal(horizontal)
      project(altitude: horizontal.altitude, azimuth: horizontal.azimuth)
    end

    def step_toward(coordinates, position_angle)
      right_ascension = coordinates.right_ascension
      declination = coordinates.declination
      east = [-right_ascension.sin, right_ascension.cos, 0.0]
      north = [
        -declination.sin * right_ascension.cos,
        -declination.sin * right_ascension.sin,
        declination.cos
      ]
      point = [
        declination.cos * right_ascension.cos,
        declination.cos * right_ascension.sin,
        declination.sin
      ]
      nearby = Geometry.normalize(
        point.each_index.map do |axis|
          point[axis] + POSITION_ANGLE_STEP * (
            position_angle.sin * east[axis] + position_angle.cos * north[axis]
          )
        end
      )

      Astronoby::Coordinates::Equatorial.new(
        right_ascension: Astronoby::Angle.from_radians(
          Math.atan2(nearby[1], nearby[0]) % (2 * Math::PI)
        ),
        declination: Astronoby::Angle.from_radians(
          Math.asin(nearby[2].clamp(-1, 1))
        ),
        epoch: coordinates.epoch
      )
    end

    def star_horizontal(star)
      catalog = catalog_horizontal(star)
      shift = star_shift(star)
      return catalog if shift.zero?

      scale = projection(@canvas.radius)
        .scale_at(altitude: catalog.altitude, azimuth: catalog.azimuth)
      return catalog if shift * scale < STAR_POSITION_TOLERANCE

      convert(star.coordinates_at(@instant))
    end

    def catalog_horizontal(star)
      @catalog_horizontals[star] ||= convert(star.equatorial_coordinates)
    end

    def star_shift(star)
      @star_shifts[star] ||= compute_star_shift(star)
    end

    def compute_star_shift(star)
      return 0.0 if star.proper_motion_ra.nil? || elapsed_years.zero?

      rate = Math.hypot(
        proper_motion_bound(star.proper_motion_ra),
        proper_motion_bound(star.proper_motion_dec)
      ) * SECONDS_PER_JULIAN_YEAR
      velocity = (star.radial_velocity&.meters_per_second || 0).abs
      seconds = elapsed_years * SECONDS_PER_JULIAN_YEAR
      parallax = star.parallax&.radians || 0
      slack = velocity / SPEED_OF_LIGHT +
        velocity * seconds * parallax / ASTRONOMICAL_UNIT
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

    def view_reach(margin)
      quarter = @view.field_of_view.radians / 4.0

      2 * Math.atan(Math.tan(quarter) * (1 + margin / @canvas.radius))
    end

    def cosine_from_view(horizontal)
      east, north, up = view_direction

      horizontal.altitude.cos *
        (horizontal.azimuth.cos * east + horizontal.azimuth.sin * north) +
        horizontal.altitude.sin * up
    end

    def convert(coordinates)
      case coordinates.epoch
      when Astronoby::JulianDate::J2000
        @transformation.apply(coordinates)
      when @instant.tt
        horizontal_of_date(coordinates)
      else
        raise ArgumentError,
          "coordinates must be at J2000 or at the date of the chart"
      end
    end

    def horizontal_of_date(coordinates)
      Astronoby::Coordinates::Equatorial.new(
        right_ascension: coordinates.right_ascension,
        declination: coordinates.declination,
        hour_angle: Astronoby::Angle.from_hours(
          (sidereal_time - coordinates.right_ascension.hours) %
            Astronoby::Constants::HOURS_PER_DAY
        ),
        epoch: coordinates.epoch
      ).to_horizontal(time: @instant.to_time, observer: @observer)
    end

    def sidereal_time
      @sidereal_time ||= Astronoby::LocalApparentSiderealTime.from_utc(
        @instant.to_time,
        longitude: @observer.longitude
      ).time
    end

    def projection(radius)
      @projections[radius] ||= if full_sky?
        Projection::Stereographic.new(center: @canvas.center, radius: radius)
      else
        center = view_center
        Projection::ObliqueStereographic.new(
          center: @canvas.center,
          radius: radius,
          altitude: center.altitude,
          azimuth: center.azimuth,
          field_of_view: @view.field_of_view,
          orientation: @view.orientation,
          pole: celestial_pole,
          rotation: @view.rotation,
          mirrored: @view.mirrored
        )
      end
    end

    def view_center
      @view_center ||= to_horizontal(@view.center)
    end

    def celestial_pole
      latitude = @observer.latitude

      [latitude.cos, 0.0, latitude.sin]
    end

    def view_direction
      @view_direction ||= Horizon.direction([view_center])
    end

    def distance_to_segment(point, from, to)
      dx = to.x - from.x
      dy = to.y - from.y
      length = dx * dx + dy * dy
      return Math.hypot(from.x - point.x, from.y - point.y) if length.zero?

      along = (((point.x - from.x) * dx + (point.y - from.y) * dy) / length)
        .clamp(0, 1)

      Math.hypot(from.x + along * dx - point.x, from.y + along * dy - point.y)
    end
  end
end
