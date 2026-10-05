# frozen_string_literal: true

module Skymap
  class Context
    attr_reader :canvas

    def initialize(observer:, instant:, canvas:)
      @observer = observer
      @instant = instant
      @canvas = canvas
      @horizontal = {}
      @projections = {}
    end

    def horizontal(star)
      coordinates = star.equatorial_coordinates
      key = [
        coordinates.right_ascension,
        coordinates.declination,
        coordinates.epoch
      ]

      @horizontal[key] ||= Astronoby::DeepSkyObject
        .new(equatorial_coordinates: coordinates)
        .at(@instant)
        .observed_by(@observer)
        .horizontal
    end

    def position(star)
      horizontal = horizontal(star)
      project(altitude: horizontal.altitude, azimuth: horizontal.azimuth)
    end

    def project(altitude:, azimuth:, radius: @canvas.radius)
      projection(radius).project(altitude: altitude, azimuth: azimuth)
    end

    private

    def projection(radius)
      @projections[radius] ||= Projection::Stereographic.new(
        center: @canvas.center,
        radius: radius
      )
    end
  end
end
