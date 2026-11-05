# frozen_string_literal: true

module Skymap
  class Chart
    def initialize(observer:, instant:, canvas:, theme: Theme.dark, view: nil)
      @observer = observer
      @instant = instant
      @canvas = canvas
      @theme = theme
      @view = view
    end

    def render(*layers)
      context = Context.new(
        observer: @observer,
        instant: @instant,
        canvas: @canvas,
        view: @view
      )
      elements = layers.flat_map { |layer| layer.elements(context) }

      Renderer::SVG.new(canvas: @canvas, theme: @theme, clipped: !@view.nil?)
        .render(elements)
    end
  end
end
