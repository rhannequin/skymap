# frozen_string_literal: true

module Skymap
  class Context
    MAX_ANGLE_FROM_VIEW_COSINE = Math.cos(150 * Math::PI / 180)

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
      @projections = {}
    end

    def horizontal(star)
      horizontal_coordinates(star.equatorial_coordinates)
    end

    def horizontal_coordinates(coordinates)
      key = [
        coordinates.right_ascension,
        coordinates.declination,
        coordinates.epoch
      ]

      @horizontal[key] ||= convert(coordinates)
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

      east, north, up = view_direction
      cosine = horizontal.altitude.cos *
        (horizontal.azimuth.cos * east + horizontal.azimuth.sin * north) +
        horizontal.altitude.sin * up
      cosine > MAX_ANGLE_FROM_VIEW_COSINE
    end

    private

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
          field_of_view: @view.field_of_view
        )
      end
    end

    def view_center
      @view_center ||= if @view.center.is_a?(Astronoby::Coordinates::Equatorial)
        horizontal_coordinates(@view.center)
      else
        @view.center
      end
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
