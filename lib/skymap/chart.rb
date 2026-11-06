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
      elements = horizon(context) +
        layers.flat_map { |layer| layer.elements(context) }

      Renderer::SVG.new(canvas: @canvas, theme: @theme, clipped: !@view.nil?)
        .render(LabelPlacement.new(canvas: @canvas).arrange(elements))
    end

    private

    def horizon(context)
      return [] if context.full_sky?

      Horizon.line(context).map do |points|
        Renderer::HorizonLine.new(points: points)
      end
    end
  end
end
