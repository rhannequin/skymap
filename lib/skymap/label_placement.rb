# frozen_string_literal: true

module Skymap
  class LabelPlacement
    RANKS = %i[field planet star deep_sky].freeze
    MARGIN_RATIO = 0.25
    GAP_RATIO = 0.5
    DOT_RATIO = 0.25
    CELL_RATIO = 4
    DIAGONAL = Math.sqrt(0.5)
    DIRECTIONS = [
      [0, 1], [0, -1], [1, 0], [-1, 0], [1, 1], [-1, 1], [1, -1], [-1, -1]
    ].freeze

    Box = Data.define(:left, :top, :right, :bottom) do
      def intersects?(other)
        left < other.right && other.left < right &&
          top < other.bottom && other.top < bottom
      end

      def bounds
        self
      end

      def blocks?(other)
        intersects?(other)
      end

      def reaches?(x, y, radius)
        dx = [left - x, 0, x - right].max
        dy = [top - y, 0, y - bottom].max

        dx * dx + dy * dy < radius * radius
      end

      def crossed_by?(from, to)
        dx = to.x - from.x
        dy = to.y - from.y
        entering = 0.0
        leaving = 1.0

        [
          [-dx, from.x - left], [dx, right - from.x],
          [-dy, from.y - top], [dy, bottom - from.y]
        ].each do |direction, distance|
          if direction.zero?
            return false if distance.negative?
          else
            ratio = distance / direction
            if direction.negative?
              entering = ratio if ratio > entering
            elsif ratio < leaving
              leaving = ratio
            end
          end
        end

        entering <= leaving
      end
    end

    Disc = Data.define(:center, :radius) do
      def bounds
        Box.new(
          left: center.x - radius, top: center.y - radius,
          right: center.x + radius, bottom: center.y + radius
        )
      end

      def blocks?(box)
        box.reaches?(center.x, center.y, radius)
      end
    end

    Segment = Data.define(:from, :to, :bounds) do
      def self.between(from, to)
        new(
          from: from,
          to: to,
          bounds: Box.new(
            left: [from.x, to.x].min, top: [from.y, to.y].min,
            right: [from.x, to.x].max, bottom: [from.y, to.y].max
          )
        )
      end

      def blocks?(box)
        bounds.intersects?(box) && box.crossed_by?(from, to)
      end
    end

    class Index
      def initialize(cell, limit)
        @cell = cell
        @last = (limit / cell).floor
        @cells = {}
      end

      def add(blocker)
        cells_of(blocker.bounds) { |cell| (@cells[cell] ||= []) << blocker }
      end

      def blocked?(box)
        cells_of(box) do |cell|
          blockers = @cells[cell]
          return true if blockers&.any? { |blocker| blocker.blocks?(box) }
        end

        false
      end

      private

      def cells_of(box)
        rows = span(box.top, box.bottom)

        span(box.left, box.right).each do |column|
          rows.each { |row| yield [column, row] }
        end
      end

      def span(from, to)
        [(from / @cell).floor, 0].max..[(to / @cell).floor, @last].min
      end
    end
    private_constant :Box, :Disc, :Segment, :Index

    def initialize(canvas:)
      @canvas = canvas
    end

    def arrange(elements)
      captions = elements.select { |element| anchored?(element) }
      return elements if captions.empty?

      text_size = captions.map(&:size).min
      index = Index.new(CELL_RATIO * text_size, @canvas.size)
      fixed_boxes(elements).each { |box| index.add(box) }
      obstacles(elements, text_size).each { |obstacle| index.add(obstacle) }
      placed = {}.compare_by_identity

      by_priority(captions).each do |caption|
        position = free_position(caption, index)
        next unless position

        index.add(box(caption, position))
        placed[caption] = caption.with(position: position)
      end

      elements.filter_map do |element|
        anchored?(element) ? placed[element] : element
      end
    end

    private

    def anchored?(element)
      element.is_a?(Renderer::Caption) && !element.anchor.nil?
    end

    def by_priority(captions)
      captions.each_with_index
        .sort_by { |caption, index| [rank(caption.kind), index] }
        .map(&:first)
    end

    def rank(kind)
      RANKS.index(kind) || RANKS.size
    end

    def fixed_boxes(elements)
      elements.filter_map do |element|
        next unless text?(element) && !anchored?(element)

        box(element, element.position)
      end
    end

    def text?(element)
      element.is_a?(Renderer::Caption) || element.is_a?(Renderer::Label)
    end

    def obstacles(elements, text_size)
      bright = DOT_RATIO * text_size

      elements.flat_map do |element|
        case element
        when Renderer::DeepSkySymbol then symbol(element)
        when Renderer::Planet, Renderer::Moon, Renderer::Sun
          [Disc.new(center: element.center, radius: element.radius)]
        when Renderer::Dot
          next [] if element.radius < bright

          [Disc.new(center: element.center, radius: element.radius)]
        else
          []
        end
      end
    end

    def symbol(symbol)
      unless symbol.hollow?
        return [Disc.new(center: symbol.center, radius: symbol.semi_major)]
      end

      points = symbol.outline

      points.zip(points.rotate).map { |from, to| Segment.between(from, to) }
    end

    def free_position(caption, index)
      candidates(caption).find do |position, check_sky|
        !index.blocked?(box(caption, position)) &&
          (!check_sky || inside_sky?(caption, position))
      end&.first
    end

    def candidates(caption)
      around = DIRECTIONS.map { |direction| [at(caption, direction), true] }

      [[caption.position, false]] + around
    end

    def at(caption, direction)
      anchor = caption.anchor
      size = caption.size
      ux, uy = direction
      reach_x = uy.zero? ? caption.clearance : caption.clearance * DIAGONAL
      reach_y = ux.zero? ? caption.clearance : caption.clearance * DIAGONAL
      gap = GAP_RATIO * size

      Point.new(
        x: anchor.x + ux * (reach_x + gap + caption.width / 2),
        y: anchor.y + uy * (reach_y + size)
      )
    end

    def inside_sky?(caption, position)
      half_width = caption.width / 2
      half_height = caption.size / 2

      [-1, 1].product([-1, 1]).all? do |sx, sy|
        Math.hypot(
          position.x + sx * half_width - @canvas.center.x,
          position.y + sy * half_height - @canvas.center.y
        ) <= @canvas.radius
      end
    end

    def box(text, position)
      margin = MARGIN_RATIO * text.size
      half_width = text.width / 2 + margin
      half_height = text.size / 2 + margin

      Box.new(
        left: position.x - half_width,
        top: position.y - half_height,
        right: position.x + half_width,
        bottom: position.y + half_height
      )
    end
  end
end
