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

      @horizontal[key] ||= @transformation.apply(coordinates)
    end

    def horizontal_position(position)
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
      @view_center ||= horizontal_position(@view.center)
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
