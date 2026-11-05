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

    def full_sky?
      @view.nil?
    end

    def in_view?(point, margin = 0)
      return true if full_sky?

      distance = Math.hypot(point.x - @canvas.center.x,
        point.y - @canvas.center.y)
      distance <= @canvas.radius + margin
    end

    def reachable?(horizontal)
      return true if full_sky?

      direction = Horizon.direction([horizontal])
      cosine = direction.zip(view_direction).sum { |a, b| a * b }
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
      @view_center ||= if @view.center.is_a?(Astronoby::Coordinates::Equatorial)
        horizontal_coordinates(@view.center)
      else
        @view.center
      end
    end

    def view_direction
      @view_direction ||= Horizon.direction([view_center])
    end
  end
end
