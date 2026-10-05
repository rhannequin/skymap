# frozen_string_literal: true

module Skymap
  class Chart
    def initialize(observer:, instant:, canvas:)
      @observer = observer
      @instant = instant
      @canvas = canvas
    end

    def render(*layers)
      context = Context.new(
        observer: @observer,
        instant: @instant,
        canvas: @canvas
      )
      elements = layers.flat_map { |layer| layer.elements(context) }

      Renderer::SVG.new(canvas: @canvas).render(elements)
    end
  end
end
