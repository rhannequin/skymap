# frozen_string_literal: true

module Skymap
  module Layers
    class ConstellationNames
      NAME_SIZE_RATIO = 0.028

      def initialize(lines:, stars:, names: Catalog::ConstellationNames.new)
        @lines = lines
        @stars = stars
        @names = names
      end

      def elements(context)
        stars_by_hr = @stars.to_h { |star| [star.hr, star] }

        @lines.group_by(&:constellation).filter_map do |abbreviation, lines|
          hrs = lines.flat_map { |line| line.from + line.to }.uniq
          stars = stars_by_hr.values_at(*hrs).compact
          risen = stars.reject do |star|
            context.horizontal(star).altitude.negative?
          end
          next if risen.size * 2 <= stars.size

          name = @names[abbreviation]
          next unless name

          Renderer::Caption.new(
            position: Point.midpoint(risen.map { |s| context.position(s) }),
            text: name,
            size: NAME_SIZE_RATIO * context.canvas.radius,
            kind: :constellation
          )
        end
      end
    end
  end
end
