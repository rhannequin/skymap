# frozen_string_literal: true

module Skymap
  module Layers
    class Grid
      DEFAULT_STEP = 30
      LINE_WIDTH_RATIO = 0.0025
      STEP_IN_DEGREES = 1

      def initialize(step: DEFAULT_STEP)
        unless step.is_a?(Integer) && step.between?(1, 90) && (360 % step).zero?
          raise ArgumentError,
            "step must be a whole number of degrees between 1 and 90 " \
            "that divides 360"
        end

        @lines = parallels(step) + meridians(step)
      end

      def elements(context)
        width = LINE_WIDTH_RATIO * context.canvas.radius

        @lines.flat_map { |line|
          Horizon.joined(Horizon.visible_runs(context, line))
        }.map do |points|
          Renderer::Grid.new(points: points, width: width)
        end
      end

      private

      def parallels(step)
        declinations = (step...90).step(step).flat_map { |degrees|
          [degrees, -degrees]
        } + [0]

        declinations.map do |declination|
          points = (0...360).step(STEP_IN_DEGREES).map do |right_ascension|
            point_at(right_ascension, declination)
          end
          points + points.first(1)
        end
      end

      def meridians(step)
        (0...360).step(step).map do |right_ascension|
          (-90..90).step(STEP_IN_DEGREES).map do |declination|
            point_at(right_ascension, declination)
          end
        end
      end

      def point_at(right_ascension, declination)
        Astronoby::Coordinates::Equatorial.new(
          right_ascension: Astronoby::Angle.from_degrees(right_ascension),
          declination: Astronoby::Angle.from_degrees(declination),
          epoch: Astronoby::JulianDate::J2000
        )
      end
    end
  end
end
