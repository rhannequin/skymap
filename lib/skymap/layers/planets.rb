# frozen_string_literal: true

module Skymap
  module Layers
    class Planets
      DEFAULT_MAGNITUDE_LIMIT = 5
      BODIES = [
        Astronoby::Mercury,
        Astronoby::Venus,
        Astronoby::Mars,
        Astronoby::Jupiter,
        Astronoby::Saturn,
        Astronoby::Uranus,
        Astronoby::Neptune
      ].freeze

      def initialize(ephem:, magnitude_limit: DEFAULT_MAGNITUDE_LIMIT)
        @ephem = ephem
        @magnitude_limit = magnitude_limit
      end

      def elements(context)
        star_size = StarSize.for(
          canvas: context.canvas,
          magnitude_limit: @magnitude_limit
        )

        BODIES.filter_map do |body_class|
          planet = body_class.at(context.instant, ephem: @ephem)
          magnitude = planet.apparent_magnitude
          next if magnitude > @magnitude_limit

          horizontal = planet.observed_by(context.observer).horizontal
          next if horizontal.altitude.negative?

          Renderer::Planet.new(
            center: context.project(
              altitude: horizontal.altitude,
              azimuth: horizontal.azimuth
            ),
            radius: star_size.radius(magnitude)
          )
        end
      end
    end
  end
end
