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
        Skymap::Renderer::Dot.new(center: point(100, 150), radius: 4),
        Skymap::Renderer::Dot.new(center: point(250, 300), radius: 0.5)
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
        center: point(109.25833333, 59.63552),
        radius: 1.23456
      )

      svg = renderer.render([dot])
      _sky, star = circles_in(svg)

      expect(star["cx"]).to eq("109.26")
      expect(star["cy"]).to eq("59.64")
      expect(star["r"]).to eq("1.23")
    end

    it "draws each label as centered text" do
      canvas = Skymap::Canvas.new(size: 400, padding: 20)
      renderer = described_class.new(canvas: canvas)
      label = Skymap::Renderer::Label.new(
        position: point(200, 10),
        text: "N",
        size: 12
      )

      svg = renderer.render([label])
      text = texts_in(svg).first

      expect(text.text.strip).to eq("N")
      expect(text["x"]).to eq("200")
      expect(text["y"]).to eq("10")
      expect(text["font-size"]).to eq("12")
      expect(text["text-anchor"]).to eq("middle")
      expect(text["dominant-baseline"]).to eq("central")
      expect(text["fill"]).to eq("#3262a8")
    end

    it "rounds label coordinates and sizes to 2 decimals" do
      canvas = Skymap::Canvas.new(size: 400, padding: 20)
      renderer = described_class.new(canvas: canvas)
      label = Skymap::Renderer::Label.new(
        position: point(109.25833333, 59.63552),
        text: "N",
        size: 1.23456
      )

      svg = renderer.render([label])
      text = texts_in(svg).first

      expect(text["x"]).to eq("109.26")
      expect(text["y"]).to eq("59.64")
      expect(text["font-size"]).to eq("1.23")
    end

    it "draws each line" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas)
      dot = Skymap::Renderer::Dot.new(center: point(100, 150), radius: 4)
      line = Skymap::Renderer::Line.new(
        from: point(100, 150),
        to: point(250, 300),
        width: 1.5
      )

      svg = renderer.render([line, dot])
      drawn = lines_in(svg).first

      expect(drawn["x1"]).to eq("100")
      expect(drawn["y1"]).to eq("150")
      expect(drawn["x2"]).to eq("250")
      expect(drawn["y2"]).to eq("300")
      expect(drawn["stroke-width"]).to eq("1.5")
      expect(drawn["stroke"]).to eq("#46689c")
    end

    it "rounds line coordinates and widths to 2 decimals" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas)
      line = Skymap::Renderer::Line.new(
        from: point(109.25833333, 59.63552),
        to: point(250.004, 300.996),
        width: 1.23456
      )

      svg = renderer.render([line])
      drawn = lines_in(svg).first

      expect(drawn["x1"]).to eq("109.26")
      expect(drawn["y1"]).to eq("59.64")
      expect(drawn["x2"]).to eq("250.0")
      expect(drawn["y2"]).to eq("301.0")
      expect(drawn["stroke-width"]).to eq("1.23")
    end

    it "draws each boundary as a dashed polyline" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas)
      boundary = Skymap::Renderer::Boundary.new(
        points: [point(100, 150), point(120.256, 180.004), point(250, 300)],
        width: 1.5
      )

      svg = renderer.render([boundary])
      drawn = polylines_in(svg).first

      expect(drawn["points"]).to eq("100,150 120.26,180.0 250,300")
      expect(drawn["fill"]).to eq("none")
      expect(drawn["stroke"]).to eq("#2b3f5e")
      expect(drawn["stroke-width"]).to eq("1.5")
      expect(drawn["stroke-dasharray"]).to eq("6.0 6.0")
    end

    it "draws elements in the given order, on top of the sky" do
      canvas = Skymap::Canvas.new(size: 400, padding: 20)
      renderer = described_class.new(canvas: canvas)
      elements = [
        Skymap::Renderer::Label.new(
          position: point(200, 10),
          text: "N",
          size: 12
        ),
        Skymap::Renderer::Dot.new(center: point(100, 150), radius: 4),
        Skymap::Renderer::Line.new(
          from: point(100, 150),
          to: point(250, 300),
          width: 1
        )
      ]

      svg = renderer.render(elements)
      order = REXML::Document.new(svg).root.elements.map(&:name)

      expect(order).to eq(%w[circle text circle line])
    end

    it "refuses an element it cannot draw" do
      canvas = Skymap::Canvas.new(size: 400, padding: 20)
      renderer = described_class.new(canvas: canvas)

      expect { renderer.render(["N"]) }
        .to raise_error(ArgumentError, "unknown element: String")
    end
  end

  def point(x, y)
    Skymap::Point.new(x: x, y: y)
  end
end
