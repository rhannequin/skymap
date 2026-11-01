# frozen_string_literal: true

RSpec.describe Skymap::Renderer::Caption do
  describe ".beside" do
    it "puts the caption under a body in the upper half of the map" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)

      caption = described_class.beside(
        center: Skymap::Point.new(x: 200, y: 100),
        radius: 3,
        canvas: canvas,
        text: "Vega",
        kind: :star
      )

      expect(caption.position.x).to eq(200)
      expect(caption.position.y).to be_within(0.001).of(
        100 + 3 + caption.size
      )
      expect(caption.text).to eq("Vega")
      expect(caption.kind).to eq(:star)
    end

    it "puts the caption over a body in the lower half of the map" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)

      caption = described_class.beside(
        center: Skymap::Point.new(x: 200, y: 300),
        radius: 3,
        canvas: canvas,
        text: "Vega",
        kind: :star
      )

      expect(caption.position.y).to be_within(0.001).of(
        300 - 3 - caption.size
      )
    end

    it "sizes the caption with the canvas" do
      canvas = Skymap::Canvas.new(size: 800, padding: 0)

      caption = described_class.beside(
        center: Skymap::Point.new(x: 400, y: 300),
        radius: 3,
        canvas: canvas,
        text: "Vega",
        kind: :star
      )

      expect(caption.size).to be_within(0.001).of(11.2)
    end

    it "moves the caption of a body at the edge of the sky inside it" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)

      caption = described_class.beside(
        center: Skymap::Point.new(x: 398, y: 200),
        radius: 3,
        canvas: canvas,
        text: "Polaris Australis",
        kind: :star
      )
      half_width = 17 * caption.size * 0.55 / 2
      edge = 200 + Math.sqrt(200**2 - (caption.position.y - 200)**2)

      expect(caption.position.x + half_width).to be_within(0.001).of(edge)
    end

    it "moves the caption of a body at the west edge inside the sky" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)

      caption = described_class.beside(
        center: Skymap::Point.new(x: 2, y: 200),
        radius: 3,
        canvas: canvas,
        text: "Vega",
        kind: :star
      )
      half_width = 4 * caption.size * 0.55 / 2
      edge = 200 - Math.sqrt(200**2 - (caption.position.y - 200)**2)

      expect(caption.position.x - half_width).to be_within(0.001).of(edge)
    end

    it "keeps the caption of a body inside the sky where it is" do
      canvas = Skymap::Canvas.new(size: 400, padding: 0)

      caption = described_class.beside(
        center: Skymap::Point.new(x: 150, y: 120),
        radius: 3,
        canvas: canvas,
        text: "Vega",
        kind: :star
      )

      expect(caption.position.x).to eq(150)
    end
  end
end
