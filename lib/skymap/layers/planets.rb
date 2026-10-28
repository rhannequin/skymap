# frozen_string_literal: true

module Skymap
  module Layers
    class Planets
      DEFAULT_MAGNITUDE_LIMIT = 5
      NAME_SIZE_RATIO = 0.028
      BODIES = [
        Astronoby::Mercury,
        Astronoby::Venus,
        Astronoby::Mars,
        Astronoby::Jupiter,
        Astronoby::Saturn,
        Astronoby::Uranus,
        Astronoby::Neptune
      ].freeze

      def initialize(
        ephem:,
        magnitude_limit: DEFAULT_MAGNITUDE_LIMIT,
        labels: false
      )
        @ephem = ephem
        @magnitude_limit = magnitude_limit
        @labels = labels
      end

      def elements(context)
        star_size = StarSize.for(
          canvas: context.canvas,
          magnitude_limit: @magnitude_limit
        )

        BODIES.flat_map do |body_class|
          planet = body_class.at(context.instant, ephem: @ephem)
          magnitude = planet.apparent_magnitude
          next [] if magnitude > @magnitude_limit

          horizontal = planet.observed_by(context.observer).horizontal
          next [] if horizontal.altitude.negative?

          center = context.project(
            altitude: horizontal.altitude,
            azimuth: horizontal.azimuth
          )
          radius = star_size.radius(magnitude)
          drawn = [Renderer::Planet.new(center: center, radius: radius)]
          drawn << caption(body_class, center, radius, context) if @labels
          drawn
        end
      end

      private

      def caption(body_class, center, radius, context)
        size = NAME_SIZE_RATIO * context.canvas.radius

        Renderer::Caption.new(
          position: Point.new(x: center.x, y: center.y + radius + size),
          text: body_class.name.split("::").last,
          size: size,
          kind: :planet
        )
      end
    end
  end
end
