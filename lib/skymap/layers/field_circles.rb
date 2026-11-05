# frozen_string_literal: true

module Skymap
  module Layers
    class FieldCircles
      LINE_WIDTH_RATIO = 0.004
      MAX_DEVIATION = 0.1
      MIN_SAMPLES = 16
      MAX_SAMPLES = 360

      def initialize(fields:, center: nil, labels: false)
        check_fields(fields)
        check_center(center)

        @fields = fields
        @center = center
        @labels = labels
      end

      def elements(context)
        center = center_in(context)
        return [] unless center

        frame = frame_around(center)
        width = LINE_WIDTH_RATIO * context.canvas.radius

        @fields.flat_map do |field|
          circle(context, center, frame, field, width)
        end
      end

      private

      def circle(context, center, frame, field, width)
        radius = Astronoby::Angle.from_radians(field.true_field.radians / 2.0)
        samples = sample_count(context, center, radius)
        path = path_of(context, ring(context, frame, radius, samples))
        runs = Horizon.joined(Horizon.runs_of(context, path))
        return [] if runs.empty?

        circles = runs.map do |points|
          Renderer::FieldCircle.new(points: points, width: width)
        end
        circles + caption(context, field, path.compact)
      end

      def sample_count(context, center, radius)
        pixels = context.span(
          radius,
          altitude: center.altitude,
          azimuth: center.azimuth
        )
        step = Math.acos([1 - MAX_DEVIATION / pixels, -1].max)

        samples = (Math::PI / step).ceil.clamp(MIN_SAMPLES, MAX_SAMPLES)

        samples + -samples % 4
      end

      def ring(context, frame, radius, samples)
        forward, side, up = frame
        points = (0...samples).map do |index|
          angle = 2 * Math::PI * index / samples
          direction = (0..2).map do |axis|
            radius.cos * forward[axis] +
              radius.sin * (Math.cos(angle) * side[axis] +
                Math.sin(angle) * up[axis])
          end
          Astronoby::Coordinates::Horizontal.new(
            altitude: Astronoby::Angle.from_radians(
              Math.asin(direction[2].clamp(-1, 1))
            ),
            azimuth: Astronoby::Angle.from_radians(
              Math.atan2(direction[1], direction[0])
            ),
            observer: context.observer
          )
        end

        points + points.first(1)
      end

      def path_of(context, horizontals)
        [position(context, horizontals.first)] +
          horizontals.each_cons(2).flat_map do |from, to|
            crossing(context, from, to) + [position(context, to)]
          end
      end

      def crossing(context, from, to)
        return [] unless context.full_sky?

        Horizon.crossing_point(context, from, to)
      end

      def position(context, horizontal)
        return if context.full_sky? && horizontal.altitude.negative?
        return unless context.reachable?(horizontal)

        context.project(
          altitude: horizontal.altitude,
          azimuth: horizontal.azimuth
        )
      end

      def caption(context, field, points)
        return [] unless @labels

        xs, ys = points.map(&:x), points.map(&:y)
        caption = Renderer::Caption.beside(
          center: Point.new(
            x: (xs.min + xs.max) / 2.0,
            y: (ys.min + ys.max) / 2.0
          ),
          radius: (ys.max - ys.min) / 2.0,
          canvas: context.canvas,
          text: field.label,
          kind: :field
        )

        context.in_view?(caption.position) ? [caption] : []
      end

      def center_in(context)
        center = @center || context.view&.center
        return unless center

        context.to_horizontal(center)
      end

      def frame_around(center)
        Geometry.frame(
          [
            center.altitude.cos * center.azimuth.cos,
            center.altitude.cos * center.azimuth.sin,
            center.altitude.sin
          ]
        )
      end

      def check_fields(fields)
        valid = fields.is_a?(Array) && !fields.empty? &&
          fields.all? { |field| field?(field) }
        return if valid

        raise ArgumentError,
          "fields must be a list of Skymap::Field or Skymap::Setup, " \
          "or anything with a true_field angle and a label"
      end

      def field?(field)
        field.respond_to?(:true_field) && field.respond_to?(:label) &&
          field.true_field.is_a?(Astronoby::Angle) &&
          field.true_field.positive? && field.true_field.radians <= Math::PI &&
          field.label.is_a?(String)
      end

      def check_center(center)
        return if center.nil? ||
          center.is_a?(Astronoby::Coordinates::Equatorial) ||
          center.is_a?(Astronoby::Coordinates::Horizontal)

        raise ArgumentError,
          "center must be equatorial or horizontal coordinates"
      end
    end
  end
end
