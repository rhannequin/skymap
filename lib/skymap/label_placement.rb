# frozen_string_literal: true

module Skymap
  class LabelPlacement
    RANKS = %i[field planet star deep_sky].freeze
    MARGIN_RATIO = 0.25
    GAP_RATIO = 0.5
    DOT_RATIO = 0.25
    DIAGONAL = Math.sqrt(0.5)
    DIRECTIONS = [
      [0, 1], [0, -1], [1, 0], [-1, 0], [1, 1], [-1, 1], [1, -1], [-1, -1]
    ].freeze

    Box = Data.define(:left, :top, :right, :bottom) do
      def intersects?(other)
        left < other.right && other.left < right &&
          top < other.bottom && other.top < bottom
      end

      def reaches?(x, y, radius)
        dx = [left - x, 0, x - right].max
        dy = [top - y, 0, y - bottom].max

        dx * dx + dy * dy < radius * radius
      end
    end
    private_constant :Box

    def initialize(canvas:)
      @canvas = canvas
    end

    def arrange(elements)
      boxes = fixed_boxes(elements)
      circles = circles(elements)
      placed = {}.compare_by_identity

      by_priority(elements.select { |element| anchored?(element) })
        .each do |caption|
          position = free_position(caption, boxes, circles)
          next unless position

          boxes << box(caption, position)
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

    def circles(elements)
      bright = DOT_RATIO * Renderer::Caption.size_for(@canvas)

      elements.filter_map do |element|
        case element
        when Renderer::DeepSkySymbol
          [element.center, element.semi_major]
        when Renderer::Planet, Renderer::Moon, Renderer::Sun
          [element.center, element.radius]
        when Renderer::Dot
          [element.center, element.radius] if element.radius >= bright
        end
      end
    end

    def free_position(caption, boxes, circles)
      candidates(caption).find do |position, check_sky|
        free?(box(caption, position), boxes, circles) &&
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
        x: anchor.x + ux * (reach_x + gap + width(caption) / 2),
        y: anchor.y + uy * (reach_y + size)
      )
    end

    def free?(candidate, boxes, circles)
      boxes.none? { |other| candidate.intersects?(other) } &&
        circles.none? do |center, radius|
          candidate.reaches?(center.x, center.y, radius)
        end
    end

    def inside_sky?(caption, position)
      half_width = width(caption) / 2
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
      half_width = width(text) / 2 + margin
      half_height = text.size / 2 + margin

      Box.new(
        left: position.x - half_width,
        top: position.y - half_height,
        right: position.x + half_width,
        bottom: position.y + half_height
      )
    end

    def width(text)
      text.text.length * text.size * Renderer::CAPTION_CHARACTER_WIDTH_RATIO
    end
  end
end
