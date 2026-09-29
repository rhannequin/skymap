# frozen_string_literal: true

module Skymap
  class Chart
    MAX_RADIUS_MAGNITUDE = -1.5
    MIN_RADIUS_MAGNITUDE = 6.5
    MIN_STAR_RADIUS = 0.3
    MAX_STAR_RADIUS = 4

    def initialize(observer:, instant:, canvas:)
      @observer = observer
      @instant = instant
      @canvas = canvas
      @projection = Projection::Stereographic.new(
        center_x: canvas.center_x,
        center_y: canvas.center_y,
        radius: canvas.radius
      )
      @star_size = StarSize.new(
        brightest_magnitude: MAX_RADIUS_MAGNITUDE,
        faintest_magnitude: MIN_RADIUS_MAGNITUDE,
        min_radius: MIN_STAR_RADIUS,
        max_radius: MAX_STAR_RADIUS
      )
    end

    def render(stars)
      dots = stars.filter_map do |star|
        horizontal = horizontal_coordinates(star.equatorial_coordinates)
        next if horizontal.altitude.negative?

        x, y = @projection.project(
          altitude: horizontal.altitude,
          azimuth: horizontal.azimuth
        )
        Renderer::Dot.new(x: x, y: y, radius: @star_size.radius(star.magnitude))
      end

      Renderer::SVG.new(canvas: @canvas).render(dots)
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
