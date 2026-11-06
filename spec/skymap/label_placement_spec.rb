# frozen_string_literal: true

RSpec.describe Skymap::LabelPlacement do
  describe "#arrange" do
    it "keeps a label that has room where it is" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)
      caption = caption_at(100, 150, "Vega", canvas: canvas)

      arranged = described_class.new(canvas: canvas).arrange([caption])

      expect(arranged).to eq([caption])
    end

    it "moves a label that would cover another label" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)
      first = caption_at(100, 150, "Vega", canvas: canvas)
      second = caption_at(104, 150, "Deneb", canvas: canvas)

      arranged = described_class.new(canvas: canvas).arrange([first, second])

      expect(arranged.first).to eq(first)
      expect(overlap?(arranged.first, arranged.last)).to be(false)
      expect(arranged.last.anchor).to eq(second.anchor)
    end

    it "keeps a label next to the object it names" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)
      first = caption_at(100, 150, "Vega", canvas: canvas)
      second = caption_at(104, 150, "Deneb", canvas: canvas)

      moved = described_class.new(canvas: canvas).arrange([first, second]).last

      distance = Math.hypot(
        moved.position.x - second.anchor.x,
        moved.position.y - second.anchor.y
      )
      expect(distance).to be < 6 * second.size + second.clearance
    end

    it "leaves out a label that has no room anywhere around its object" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)
      caption = caption_at(100, 150, "Vega", canvas: canvas)
      crowd = Skymap::Renderer::Planet.new(
        center: caption.anchor,
        radius: 80
      )

      arranged = described_class.new(canvas: canvas)
        .arrange([crowd, caption])

      expect(arranged).to eq([crowd])
    end

    it "gives the room to the label of a planet before a deep-sky object" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)
      object = caption_at(100, 150, "M13", canvas: canvas, kind: :deep_sky)
      planet = caption_at(100, 150, "Mars", canvas: canvas, kind: :planet)

      arranged = described_class.new(canvas: canvas).arrange([object, planet])

      expect(arranged.last).to eq(planet)
      expect(arranged.first.position).not_to eq(object.position)
    end

    it "gives the room to the label that comes first within a kind" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)
      first = caption_at(100, 150, "M31", canvas: canvas, kind: :deep_sky)
      second = caption_at(100, 150, "M32", canvas: canvas, kind: :deep_sky)

      arranged = described_class.new(canvas: canvas).arrange([first, second])

      expect(arranged.first).to eq(first)
      expect(arranged.last.position).not_to eq(second.position)
    end

    it "keeps the order of the elements" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)
      dot = Skymap::Renderer::Dot.new(
        center: Skymap::Point.new(x: 300, y: 300),
        radius: 1
      )
      caption = caption_at(100, 150, "Vega", canvas: canvas)
      label = Skymap::Renderer::Label.new(
        position: Skymap::Point.new(x: 200, y: 10),
        text: "N",
        size: 10
      )

      arranged = described_class.new(canvas: canvas)
        .arrange([dot, caption, label])

      expect(arranged).to eq([dot, caption, label])
    end

    it "never moves a label that is not attached to an object" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)
      name = Skymap::Renderer::Caption.new(
        position: Skymap::Point.new(x: 100, y: 156),
        text: "Lyra",
        size: 11,
        kind: :constellation
      )
      star = caption_at(100, 150, "Vega", canvas: canvas)

      arranged = described_class.new(canvas: canvas).arrange([name, star])

      expect(arranged.first).to eq(name)
      expect(overlap?(name, arranged.last)).to be(false)
    end

    it "avoids a label of the map that is not a caption" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)
      star = caption_at(100, 150, "Vega", canvas: canvas)
      label = Skymap::Renderer::Label.new(
        position: star.position,
        text: "West",
        size: 11
      )

      arranged = described_class.new(canvas: canvas).arrange([label, star])

      expect(arranged.first).to eq(label)
      expect(overlap?(label, arranged.last)).to be(false)
    end

    it "avoids a deep-sky symbol" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)
      star = caption_at(100, 150, "Vega", canvas: canvas)
      symbol = Skymap::Renderer::DeepSkySymbol.new(
        center: star.position,
        kind: :galaxy,
        semi_major: 8,
        semi_minor: 4,
        rotation: 0.0,
        width: 1
      )

      arranged = described_class.new(canvas: canvas)
        .arrange([symbol, star])

      expect(arranged.last.position).not_to eq(star.position)
    end

    it "avoids a bright star but not a faint one" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)
      caption = caption_at(100, 150, "Vega", canvas: canvas)
      faint = Skymap::Renderer::Dot.new(center: caption.position, radius: 0.5)
      bright = Skymap::Renderer::Dot.new(center: caption.position, radius: 4)

      among_faint = described_class.new(canvas: canvas)
        .arrange([faint, caption])
      among_bright = described_class.new(canvas: canvas)
        .arrange([bright, caption])

      expect(among_faint.last).to eq(caption)
      expect(among_bright.last.position).not_to eq(caption.position)
    end

    it "keeps a moved label inside the sky" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)
      blocker = caption_at(380, 200, "Rigel", canvas: canvas)
      edge = caption_at(382, 200, "Betelgeuse", canvas: canvas)

      moved = described_class.new(canvas: canvas)
        .arrange([blocker, edge])
        .last

      expect(inside_sky?(moved, canvas)).to be(true)
    end

    it "gives nothing for no elements" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)

      arranged = described_class.new(canvas: canvas).arrange([])

      expect(arranged).to eq([])
    end
  end

  def caption_at(x, y, text, canvas:, kind: :star)
    Skymap::Renderer::Caption.beside(
      center: Skymap::Point.new(x: x, y: y),
      radius: 3,
      canvas: canvas,
      text: text,
      kind: kind
    )
  end

  def box_of(text)
    width = text.text.length * text.size *
      Skymap::Renderer::CAPTION_CHARACTER_WIDTH_RATIO

    [
      text.position.x - width / 2, text.position.y - text.size / 2,
      text.position.x + width / 2, text.position.y + text.size / 2
    ]
  end

  def overlap?(first, second)
    a = box_of(first)
    b = box_of(second)

    a[0] < b[2] && b[0] < a[2] && a[1] < b[3] && b[1] < a[3]
  end

  def inside_sky?(text, canvas)
    left, top, right, bottom = box_of(text)

    [left, right].product([top, bottom]).all? do |x, y|
      Math.hypot(x - canvas.center.x, y - canvas.center.y) <= canvas.radius
    end
  end
end
