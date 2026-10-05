# frozen_string_literal: true

module Skymap
  module Layers
    class CardinalDirections
      CARDINAL_DIRECTIONS = {"N" => 0, "E" => 90, "S" => 180, "W" => 270}
      CARDINAL_SIZE_RATIO = 0.6

      def elements(context)
        canvas = context.canvas

        CARDINAL_DIRECTIONS.map do |text, azimuth|
          position = context.project(
            altitude: Astronoby::Angle.zero,
            azimuth: Astronoby::Angle.from_degrees(azimuth),
            radius: canvas.radius + canvas.padding / 2.0
          )
          Renderer::Label.new(
            position: position,
            text: text,
            size: canvas.padding * CARDINAL_SIZE_RATIO
          )
        end
      end
    end
  end
end
