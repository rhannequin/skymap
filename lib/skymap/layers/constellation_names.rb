# frozen_string_literal: true

module Skymap
  module Layers
    class ConstellationNames
      def initialize(lines:, stars:, names: Catalog::ConstellationNames.new)
        @lines = lines
        @stars = stars
        @names = names
      end

      def elements(context)
        stars_by_hr = Star.by_hr(@stars)

        @lines.group_by(&:constellation).filter_map do |abbreviation, lines|
          name = @names[abbreviation]
          next unless name

          parts = parts(lines).map { |hrs| stars_by_hr.values_at(*hrs).compact }
          risen = parts.map do |stars|
            stars.reject { |star| context.horizontal(star).altitude.negative? }
          end
          next if risen.sum(&:size) * 2 <= parts.sum(&:size)

          biggest = risen.max_by(&:size)
          Renderer::Caption.new(
            position: Point.midpoint(biggest.map { |s| context.position(s) }),
            text: name,
            size: Renderer::Caption.size_for(context.canvas),
            kind: :constellation
          )
        end
      end

      private

      def parts(lines)
        lines.each_with_object([]) do |line, parts|
          hrs = line.from + line.to
          joined, others = parts.partition { |part| part.intersect?(hrs) }
          parts.replace(others << (joined.flatten + hrs).uniq)
        end
      end
    end
  end
end
