# frozen_string_literal: true

module Skymap
  class Chart
    DEFAULT_MAGNITUDE_LIMIT = 5
    MAX_RADIUS_MAGNITUDE = -1.5
    MIN_STAR_RADIUS_RATIO = 0.0025
    MAX_STAR_RADIUS_RATIO = 0.02
    STAR_SIZE_EXPONENT = 1.5
    CARDINAL_DIRECTIONS = {"N" => 0, "E" => 90, "S" => 180, "W" => 270}
    CARDINAL_SIZE_RATIO = 0.6
    LINE_WIDTH_RATIOS = {bold: 0.0044, normal: 0.003, thin: 0.0017}

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
      @label_projection = Projection::Stereographic.new(
        center_x: canvas.center_x,
        center_y: canvas.center_y,
        radius: canvas.radius + canvas.padding / 2.0
      )
      @star_size = StarSize.new(
        brightest_magnitude: MAX_RADIUS_MAGNITUDE,
        faintest_magnitude: magnitude_limit,
        min_radius: MIN_STAR_RADIUS_RATIO * canvas.radius,
        max_radius: MAX_STAR_RADIUS_RATIO * canvas.radius,
        exponent: STAR_SIZE_EXPONENT
      )
    end

    def render(stars, lines: [])
      stars = stars.to_a
      horizontal = Hash.new do |positions, star|
        positions[star] = horizontal_coordinates(star.equatorial_coordinates)
      end

      Renderer::SVG.new(canvas: @canvas).render(
        dots: dots(stars, horizontal),
        labels: cardinal_labels,
        lines: line_segments(stars, lines, horizontal)
      )
    end

    private

    def dots(stars, horizontal)
      stars.filter_map do |star|
        next if star.magnitude > @magnitude_limit
        next if horizontal[star].altitude.negative?

        x, y = project(horizontal[star])
        Renderer::Dot.new(x: x, y: y, radius: @star_size.radius(star.magnitude))
      end
    end

    def line_segments(stars, lines, horizontal)
      stars_by_hr = stars.to_h { |star| [star.hr, star] }

      lines.filter_map do |line|
        ends = [line.from, line.to].map { |hrs| stars_by_hr.values_at(*hrs) }
        next if ends.flatten.include?(nil)

        directions = ends.map do |end_stars|
          direction(end_stars.map { |star| horizontal[star] })
        end
        next if directions.all? { |direction| direction.last.negative? }

        (x1, y1), (x2, y2) = ends.each_with_index.map do |end_stars, index|
          if directions[index].last.negative?
            project_direction(
              horizon_crossing(directions[1 - index], directions[index])
            )
          else
            midpoint(end_stars.map { |star| project(horizontal[star]) })
          end
        end
        Renderer::Line.new(
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          width: LINE_WIDTH_RATIOS.fetch(line.weight) * @canvas.radius
        )
      end
    end

    def direction(horizontals)
      vectors = horizontals.map do |horizontal|
        [
          horizontal.altitude.cos * horizontal.azimuth.cos,
          horizontal.altitude.cos * horizontal.azimuth.sin,
          horizontal.altitude.sin
        ]
      end
      vectors.transpose.map(&:sum)
    end

    def horizon_crossing(above, below)
      above.zip(below).map do |from, to|
        above.last * to - below.last * from
      end
    end

    def project_direction(direction)
      x, y, = direction
      @projection.project(
        altitude: Astronoby::Angle.zero,
        azimuth: Astronoby::Angle.from_radians(Math.atan2(y, x))
      )
    end

    def project(horizontal)
      @projection.project(
        altitude: horizontal.altitude,
        azimuth: horizontal.azimuth
      )
    end

    def midpoint(points)
      [points.sum(&:first) / points.size, points.sum(&:last) / points.size]
    end

    def cardinal_labels
      CARDINAL_DIRECTIONS.map do |text, azimuth|
        x, y = @label_projection.project(
          altitude: Astronoby::Angle.zero,
          azimuth: Astronoby::Angle.from_degrees(azimuth)
        )
        Renderer::Label.new(
          x: x,
          y: y,
          text: text,
          size: @canvas.padding * CARDINAL_SIZE_RATIO
        )
      end
    end

    def horizontal_coordinates(equatorial_coordinates)
      Astronoby::DeepSkyObject
        .new(equatorial_coordinates: equatorial_coordinates)
        .at(@instant)
        .observed_by(@observer)
        .horizontal
    end
  end
end
