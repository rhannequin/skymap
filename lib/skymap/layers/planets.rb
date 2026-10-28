# frozen_string_literal: true

module Skymap
  module Layers
    class Planets
      DEFAULT_MAGNITUDE_LIMIT = 5
      BODIES = {
        mercury: Astronoby::Mercury,
        venus: Astronoby::Venus,
        mars: Astronoby::Mars,
        jupiter: Astronoby::Jupiter,
        saturn: Astronoby::Saturn,
        uranus: Astronoby::Uranus,
        neptune: Astronoby::Neptune
      }.freeze
      NAMES = BODIES.keys.to_h { |planet| [planet, planet.to_s.capitalize] }
        .freeze

      def initialize(
        ephem:,
        magnitude_limit: DEFAULT_MAGNITUDE_LIMIT,
        labels: false,
        names: NAMES
      )
        @ephem = ephem
        @magnitude_limit = magnitude_limit
        @labels = labels
        @names = names
      end

      def elements(context)
        star_size = StarSize.for(
          canvas: context.canvas,
          magnitude_limit: @magnitude_limit
        )

        BODIES.flat_map do |planet, body_class|
          body = body_class.at(context.instant, ephem: @ephem)
          magnitude = body.apparent_magnitude
          next [] if magnitude > @magnitude_limit

          horizontal = body.observed_by(context.observer).horizontal
          next [] if horizontal.altitude.negative?

          center = context.project(
            altitude: horizontal.altitude,
            azimuth: horizontal.azimuth
          )
          radius = star_size.radius(magnitude)
          caption = caption(planet, center, radius, context) if @labels
          [Renderer::Planet.new(center: center, radius: radius), caption]
            .compact
        end
      end

      private

      def caption(planet, center, radius, context)
        name = @names[planet]
        return unless name

        size = Renderer::Caption.size_for(context.canvas)
        towards_center = (center.y > context.canvas.center.y) ? -1 : 1

        Renderer::Caption.new(
          position: Point.new(
            x: center.x,
            y: center.y + towards_center * (radius + size)
          ),
          text: name,
          size: size,
          kind: :planet
        )
      end
    end
  end
end
