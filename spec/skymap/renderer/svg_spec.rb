# frozen_string_literal: true

RSpec.describe Skymap::Renderer::SVG do
  describe "#render" do
    it "sizes the SVG to the canvas" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas)

      svg = renderer.render([])
      root = REXML::Document.new(svg).root

      expect(root.name).to eq("svg")
      expect(root["viewBox"]).to eq("0 0 400 400")
      expect(root["width"]).to eq("400")
      expect(root["height"]).to eq("400")
    end

    it "draws the sky as a dark disk outlined by the horizon" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas)

      svg = renderer.render([])
      circles = circles_in(svg)
      sky = circles.first

      expect(circles.size).to eq(1)
      expect(sky["cx"]).to eq("200.0")
      expect(sky["cy"]).to eq("200.0")
      expect(sky["r"]).to eq("198.5")
      expect(sky["fill"]).to eq("#000000")
      expect(sky["stroke"]).to eq("#3262a8")
      expect(sky["stroke-width"]).to eq("3")
    end

    it "rounds the sky geometry to 2 decimals" do
      canvas = Skymap::Canvas.new(size: 401, padding: 1.3333)
      renderer = described_class.new(canvas: canvas)

      svg = renderer.render([])
      sky = circles_in(svg).first

      expect(sky["cx"]).to eq("200.5")
      expect(sky["cy"]).to eq("200.5")
      expect(sky["r"]).to eq("199.17")
    end

    it "draws a star on top of the sky for each dot" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas)
      dots = [
        Skymap::Renderer::Dot.new(x: 100, y: 150, radius: 4),
        Skymap::Renderer::Dot.new(x: 250, y: 300, radius: 0.5)
      ]

      svg = renderer.render(dots)
      _sky, *stars = circles_in(svg)

      expect(stars.size).to eq(2)
      expect(stars[0]["cx"]).to eq("100")
      expect(stars[0]["cy"]).to eq("150")
      expect(stars[0]["r"]).to eq("4")
      expect(stars[1]["cx"]).to eq("250")
      expect(stars[1]["cy"]).to eq("300")
      expect(stars[1]["r"]).to eq("0.5")
      stars.each do |star|
        expect(star["fill"]).to eq("#ffffff")
      end
    end

    it "rounds star coordinates and radii to 2 decimals" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas)
      dot = Skymap::Renderer::Dot.new(
        x: 109.25833333,
        y: 59.63552,
        radius: 1.23456
      )

      svg = renderer.render([dot])
      _sky, star = circles_in(svg)

      expect(star["cx"]).to eq("109.26")
      expect(star["cy"]).to eq("59.64")
      expect(star["r"]).to eq("1.23")
    end
  end
end
