# frozen_string_literal: true

module Skymap
  module Layers
    class Grid
      DEFAULT_STEP = 30
      LINE_WIDTH_RATIO = 0.0025
      SAMPLING_STEP_IN_DEGREES = 1
      EPOCHS = %i[j2000 of_date].freeze

      def initialize(step: DEFAULT_STEP, epoch: :j2000)
        unless step.is_a?(Integer) && step.between?(1, 90) && (360 % step).zero?
          raise ArgumentError,
            "step must be a whole number of degrees between 1 and 90 " \
            "that divides 360"
        end

        unless EPOCHS.include?(epoch)
          raise ArgumentError, "epoch must be :j2000 or :of_date"
        end

        @step = step
        @epoch = epoch
        @lines = lines_at(Astronoby::JulianDate::J2000).freeze if j2000?
      end

      def elements(context)
        width = LINE_WIDTH_RATIO * context.canvas.radius

        lines_for(context).flat_map { |line|
          Horizon.joined(Horizon.visible_runs(context, line))
        }.map do |points|
          Renderer::Grid.new(points: points, width: width)
        end
      end

      private

      def j2000?
        @epoch == :j2000
      end

      def lines_for(context)
        return @lines if j2000?

        lines_at(context.instant.tt)
      end

      def lines_at(epoch)
        parallels(@step, epoch) + meridians(@step, epoch)
      end

      def parallels(step, epoch)
        declinations = (step...90).step(step).flat_map { |degrees|
          [degrees, -degrees]
        } + [0]

        declinations.map do |declination|
          points = (0...360).step(SAMPLING_STEP_IN_DEGREES).map do |degrees|
            point_at(degrees, declination, epoch)
          end
          points + points.first(1)
        end
      end

      def meridians(step, epoch)
        (0...360).step(step).map do |right_ascension|
          (-90..90).step(SAMPLING_STEP_IN_DEGREES).map do |declination|
            point_at(right_ascension, declination, epoch)
          end
        end
      end

      def point_at(right_ascension, declination, epoch)
        Astronoby::Coordinates::Equatorial.new(
          right_ascension: Astronoby::Angle.from_degrees(right_ascension),
          declination: Astronoby::Angle.from_degrees(declination),
          epoch: epoch
        )
      end
    end
  end
end
