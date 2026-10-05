# frozen_string_literal: true

module Skymap
  module Layers
    class ConstellationLines
      LINE_WIDTH_RATIOS = {bold: 0.0044, normal: 0.003, thin: 0.0017}

      def initialize(lines:, stars:)
        @lines = lines
        @stars = stars
      end

      def elements(context)
        stars_by_hr = @stars.to_h { |star| [star.hr, star] }

        @lines.filter_map do |line|
          ends = [line.from, line.to].map { |hrs| stars_by_hr.values_at(*hrs) }
          next if ends.flatten.include?(nil)

          directions = ends.map do |end_stars|
            direction(end_stars.map { |star| context.horizontal(star) })
          end
          next if directions.all? { |direction| direction.last.negative? }

          from, to = ends.each_with_index.map do |end_stars, index|
            if directions[index].last.negative?
              project_direction(
                context,
                horizon_crossing(directions[1 - index], directions[index])
              )
            else
              Point.midpoint(end_stars.map { |star| context.position(star) })
            end
          end
          Renderer::Line.new(
            from: from,
            to: to,
            width: LINE_WIDTH_RATIOS.fetch(line.weight) * context.canvas.radius
          )
        end
      end

      private

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

      def project_direction(context, direction)
        x, y, = direction
        context.project(
          altitude: Astronoby::Angle.zero,
          azimuth: Astronoby::Angle.from_radians(Math.atan2(y, x))
        )
      end
    end
  end
end
