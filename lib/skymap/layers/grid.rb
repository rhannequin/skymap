# frozen_string_literal: true

module Skymap
  module Layers
    class Grid
      DEFAULT_STEP = Astronoby::Angle.from_degrees(30)
      LINE_WIDTH_RATIO = 0.0025
      SAMPLING_STEP_IN_DEGREES = 1
      TOLERANCE_IN_DEGREES = 1e-9
      EPOCHS = %i[j2000 of_date].freeze
      CULL_MARGIN = Astronoby::Angle.from_degrees(
        2 * SAMPLING_STEP_IN_DEGREES
      ).radians
      AXES = [[0, 0], [90, 0], [0, 90]].freeze

      Line = Data.define(:kind, :degrees) do
        def parallel?
          kind == :parallel
        end

        def radians
          Astronoby::Angle.from_degrees(degrees).radians
        end
      end

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
        @specs = (parallels + meridians).freeze
        if j2000?
          @lines = @specs.to_h { |spec|
            [spec, points_of(spec, Astronoby::JulianDate::J2000)]
          }.freeze
        end
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
        epoch = j2000? ? Astronoby::JulianDate::J2000 : context.instant.tt

        specs_near(context, epoch).map do |spec|
          j2000? ? @lines.fetch(spec) : points_of(spec, epoch)
        end
      end

      def specs_near(context, epoch)
        return @specs if context.full_sky?

        center = view_center(context, epoch)
        limit = context.view.field_of_view.radians / 2 + CULL_MARGIN

        @specs.select { |spec| distance_to(spec, center) <= limit }
      end

      def view_center(context, epoch)
        direction = Horizon.direction(
          [context.to_horizontal(context.view.center)]
        )

        AXES.map do |right_ascension, declination|
          axis = point_at(right_ascension, declination, epoch)
          Geometry.dot(
            Horizon.direction([context.horizontal_coordinates(axis)]),
            direction
          )
        end
      end

      def distance_to(spec, center)
        x, y, z = center
        if spec.parallel?
          return (Math.asin(z.clamp(-1, 1)) - spec.radians).abs
        end

        along = x * Math.cos(spec.radians) + y * Math.sin(spec.radians)
        reach = along.negative? ? z.abs : Math.hypot(along, z)

        Math.acos(reach.clamp(-1, 1))
      end

      def divisions_of(step)
        return unless step.is_a?(Astronoby::Angle) && step.positive?

        divisions = (360 / step.degrees).round
        return unless divisions.between?(4, 360)

        divisions if (360.0 / divisions - step.degrees).abs <
          TOLERANCE_IN_DEGREES
      end

      def parallels
        circles = ((90 - TOLERANCE_IN_DEGREES) / @step).floor
        declinations = (1..circles).flat_map { |index|
          [index * @step, -index * @step]
        } + [0]

        declinations.map { |declination| Line.new(:parallel, declination) }
      end

      def meridians
        @divisions.times.map { |index| Line.new(:meridian, index * @step) }
      end

      def points_of(spec, epoch)
        if spec.parallel?
          points = (0...360).step(SAMPLING_STEP_IN_DEGREES).map do |degrees|
            point_at(degrees, spec.degrees, epoch)
          end
          points + points.first(1)
        else
          (-90..90).step(SAMPLING_STEP_IN_DEGREES).map do |declination|
            point_at(spec.degrees, declination, epoch)
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
