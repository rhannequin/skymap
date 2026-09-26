# frozen_string_literal: true

module Skymap
  class Chart
    def initialize(observer:, instant:, canvas:)
      @observer = observer
      @instant = instant
      @canvas = canvas
      @projection = Projection::Stereographic.new(
        center_x: canvas.center_x,
        center_y: canvas.center_y,
        radius: canvas.radius
      )
    end

    def render(stars)
      points = stars.filter_map do |equatorial_coordinates|
        horizontal = horizontal_coordinates(equatorial_coordinates)
        next if horizontal.altitude.negative?

        @projection.project(
          altitude: horizontal.altitude,
          azimuth: horizontal.azimuth
        )
      end

      Renderer::SVG.new(canvas: @canvas).render(points)
    end

    private

    def horizontal_coordinates(equatorial_coordinates)
      Astronoby::DeepSkyObject
        .new(equatorial_coordinates: equatorial_coordinates)
        .at(@instant)
        .observed_by(@observer)
        .horizontal
    end
  end
end
