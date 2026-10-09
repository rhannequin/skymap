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
            Horizon.direction(
              end_stars.map { |star| context.horizontal(star) }
            )
          end
          next if directions.all? { |direction| direction.last.negative? }

          from, to = ends.each_with_index.map do |end_stars, index|
            if directions[index].last.negative?
              Horizon.project(
                context,
                Horizon.crossing(directions[1 - index], directions[index])
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
    end
  end
end
