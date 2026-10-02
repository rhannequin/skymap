# frozen_string_literal: true

module Skymap
  class Chart
    DEFAULT_MAGNITUDE_LIMIT = 5
    MAX_RADIUS_MAGNITUDE = -1.5
    MIN_STAR_RADIUS_RATIO = 0.0025
    MAX_STAR_RADIUS_RATIO = 0.02
    STAR_SIZE_EXPONENT = 1.5

    def initialize(
      observer:,
      instant:,
      canvas:,
      magnitude_limit: DEFAULT_MAGNITUDE_LIMIT
    )
      @observer = observer
      @instant = instant
      @canvas = canvas
      @magnitude_limit = magnitude_limit
      @projection = Projection::Stereographic.new(
        center_x: canvas.center_x,
        center_y: canvas.center_y,
        radius: canvas.radius
      )
      @star_size = StarSize.new(
        brightest_magnitude: MAX_RADIUS_MAGNITUDE,
        faintest_magnitude: magnitude_limit,
        min_radius: MIN_STAR_RADIUS_RATIO * canvas.radius,
        max_radius: MAX_STAR_RADIUS_RATIO * canvas.radius,
        exponent: STAR_SIZE_EXPONENT
      )
    end

    def render(stars)
      dots = stars.filter_map do |star|
        next if star.magnitude > @magnitude_limit

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
