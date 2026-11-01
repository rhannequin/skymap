# frozen_string_literal: true

module Skymap
  class Chart
    def initialize(observer:, instant:, canvas:, theme: Theme.dark)
      @observer = observer
      @instant = instant
      @canvas = canvas
      @theme = theme
    end

    def render(*layers)
      context = Context.new(
        observer: @observer,
        instant: @instant,
        canvas: @canvas
      )
      elements = layers.flat_map { |layer| layer.elements(context) }

      Renderer::SVG.new(canvas: @canvas, theme: @theme).render(elements)
    end
  end
end
