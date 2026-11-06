# frozen_string_literal: true

module Skymap
  module Layers
    class DeepSkyObjects
      DEFAULT_MAGNITUDE_LIMIT = 11
      MIN_RADIUS_RATIO = 0.012
      LINE_WIDTH_RATIO = 0.003

      def initialize(
        objects:,
        magnitude_limit: DEFAULT_MAGNITUDE_LIMIT,
        labels: false
      )
        @objects = objects
        @magnitude_limit = magnitude_limit
        @labels = labels
      end

      def elements(context)
        radius = context.canvas.radius
        minimum = MIN_RADIUS_RATIO * radius
        width = LINE_WIDTH_RATIO * radius

        brightest_first.flat_map do |object|
          draw(context, object, minimum, width)
        end
      end

      private

      def brightest_first
        @objects.each_with_index
          .reject { |object, _| too_faint?(object) }
          .sort_by { |object, index| [object.magnitude || Float::INFINITY, index] }
          .map(&:first)
      end

      def too_faint?(object)
        object.magnitude && object.magnitude > @magnitude_limit
      end

      def draw(context, object, minimum, width)
        coordinates = object.equatorial_coordinates
        horizontal = context.horizontal_coordinates(coordinates)
        return [] if horizontal.altitude.negative?

        center = context.project(
          altitude: horizontal.altitude,
          azimuth: horizontal.azimuth
        )
        semi_major, semi_minor = semi_axes(context, object, horizontal, minimum)
        return [] unless context.in_view?(center, semi_major)

        drawn = Renderer::DeepSkySymbol.new(
          center: center,
          kind: object.type,
          semi_major: semi_major,
          semi_minor: semi_minor,
          rotation: rotation(context, object),
          width: width
        )

        [drawn, caption(context, object, center, semi_major)].compact
      end

      def semi_axes(context, object, horizontal, minimum)
        major, minor = axes(object)
        return [minimum, minimum] unless major

        pixels = ->(angle) {
          context.span(
            angle,
            altitude: horizontal.altitude,
            azimuth: horizontal.azimuth
          ) / 2
        }
        semi_major = pixels.call(major)
        semi_minor = pixels.call(minor)
        growth = [minimum / semi_major, 1].max

        [semi_major * growth, semi_minor * growth]
      end

      def axes(object)
        major = object.major_axis
        return unless major

        minor = object.minor_axis
        return [major, minor] if round?(object) || object.position_angle

        equal_area = Astronoby::Angle.from_radians(
          Math.sqrt(major.radians * minor.radians)
        )

        [equal_area, equal_area]
      end

      def round?(object)
        object.major_axis == object.minor_axis
      end

      def rotation(context, object)
        angle = object.position_angle
        return 0.0 if angle.nil? || round?(object)

        context.rotation_at(
          object.equatorial_coordinates,
          position_angle: angle
        ).degrees
      end

      def caption(context, object, center, radius)
        return unless @labels

        Renderer::Caption.beside(
          center: center,
          radius: radius,
          canvas: context.canvas,
          text: object.designation,
          kind: :deep_sky
        )
      end
    end
  end
end
