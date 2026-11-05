# frozen_string_literal: true

module Skymap
  module Layers
    class Grid
      DEFAULT_STEP = Astronoby::Angle.from_degrees(30)
      LINE_WIDTH_RATIO = 0.0025
      SAMPLING_STEP_IN_DEGREES = 1
      TOLERANCE_IN_DEGREES = 1e-9
      EPOCHS = %i[j2000 of_date].freeze

      def initialize(step: DEFAULT_STEP, epoch: :j2000)
        divisions = divisions_of(step)
        unless divisions
          raise ArgumentError,
            "step must be an Astronoby::Angle between 1 and 90 degrees " \
            "that divides 360 degrees"
        end

        unless EPOCHS.include?(epoch)
          raise ArgumentError, "epoch must be :j2000 or :of_date"
        end

        @divisions = divisions
        @step = 360.0 / divisions
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
        parallels(epoch) + meridians(epoch)
      end

      def divisions_of(step)
        return unless step.is_a?(Astronoby::Angle) && step.positive?

        divisions = (360 / step.degrees).round
        return unless divisions.between?(4, 360)

        divisions if (360.0 / divisions - step.degrees).abs <
          TOLERANCE_IN_DEGREES
      end

      def parallels(epoch)
        circles = ((90 - TOLERANCE_IN_DEGREES) / @step).floor
        declinations = (1..circles).flat_map { |index|
          [index * @step, -index * @step]
        } + [0]

        declinations.map do |declination|
          points = (0...360).step(SAMPLING_STEP_IN_DEGREES).map do |degrees|
            point_at(degrees, declination, epoch)
          end
          points + points.first(1)
        end
      end

      def meridians(epoch)
        right_ascensions = @divisions.times.map { |index| index * @step }

        right_ascensions.map do |right_ascension|
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
