# frozen_string_literal: true

module Skymap
  module Renderer
    DeepSkySymbol = Data.define(
      :center,
      :kind,
      :semi_major,
      :semi_minor,
      :rotation,
      :width
    ) do
      def hollow?
        DeepSkySymbol::HOLLOW_KINDS.include?(kind)
      end

      def outline
        return corners if kind == :nebula

        Array.new(DeepSkySymbol::OUTLINE_STEPS) do |step|
          angle = 2 * Math::PI * step / DeepSkySymbol::OUTLINE_STEPS

          at(semi_major * Math.cos(angle), semi_minor * Math.sin(angle))
        end
      end

      private

      def corners
        [[-1, -1], [1, -1], [1, 1], [-1, 1]].map do |sx, sy|
          at(sx * semi_major, sy * semi_minor)
        end
      end

      def at(dx, dy)
        turn = rotation * Math::PI / 180

        Point.new(
          x: center.x + dx * Math.cos(turn) - dy * Math.sin(turn),
          y: center.y + dx * Math.sin(turn) + dy * Math.cos(turn)
        )
      end
    end

    DeepSkySymbol::HOLLOW_KINDS = %i[
      galaxy
      open_cluster
      asterism
      supernova_remnant
      planetary_nebula
      nebula
    ].freeze
    DeepSkySymbol::OUTLINE_STEPS = 48
  end
end
