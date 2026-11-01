# frozen_string_literal: true

RSpec.describe Skymap::Renderer::SVG do
  describe "#render" do
    it "sizes the SVG to the canvas" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)

      svg = renderer.render([])
      root = REXML::Document.new(svg).root

      expect(root.name).to eq("svg")
      expect(root["viewBox"]).to eq("0 0 400 400")
      expect(root["width"]).to eq("400")
      expect(root["height"]).to eq("400")
    end

    it "draws the sky as a dark disk outlined by the horizon" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)

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

    it "draws with the colors of the given theme" do
      canvas = Skymap::Canvas.new(size: 400, padding: 20)
      theme = Skymap::Theme.light.with(
        constellation_name: "#010203",
        star_name: "#040506",
        planet_name: "#070809",
        font: "serif"
      )
      renderer = described_class.new(canvas: canvas, theme: theme)
      elements = one_of_each_element

      svg = renderer.render(elements)
      sky, star, planet, sun = circles_in(svg)
      line = lines_in(svg).first
      boundary, ecliptic = polylines_in(svg)
      label, *captions = texts_in(svg)

      expect(sky["fill"]).to eq(theme.sky)
      expect(sky["stroke"]).to eq(theme.horizon)
      expect(star["fill"]).to eq(theme.star)
      expect(planet["fill"]).to eq(theme.planet)
      expect(sun["fill"]).to eq(theme.sun)
      expect(line["stroke"]).to eq(theme.constellation_line)
      expect(boundary["stroke"]).to eq(theme.boundary)
      expect(ecliptic["stroke"]).to eq(theme.ecliptic)
      expect(label["fill"]).to eq(theme.label)
      expect(captions.map { |c| c["fill"] }).to eq(
        [theme.constellation_name, theme.star_name, theme.planet_name]
      )
      expect(([label] + captions).map { |t| t["font-family"] }.uniq)
        .to eq(["serif"])
    end

    it "draws the Moon with the colors of the given theme" do
      canvas = Skymap::Canvas.new(size: 400, padding: 20)
      theme = Skymap::Theme.light
      renderer = described_class.new(canvas: canvas, theme: theme)
      moon = Skymap::Renderer::Moon.new(
        center: point(100, 100),
        radius: 10,
        illuminated_fraction: 0.75,
        rotation: 0
      )

      svg = renderer.render([moon])
      shadow, lit = groups_in(svg).first.elements.to_a

      expect(shadow["fill"]).to eq(theme.moon_shadow)
      expect(shadow["fill-opacity"]).to eq(theme.moon_shadow_opacity.to_s)
      expect(lit["fill"]).to eq(theme.moon)
    end

    it "draws no background when the theme says none" do
      canvas = Skymap::Canvas.new(size: 400, padding: 20)
      renderer = described_class.new(
        canvas: canvas,
        theme: Skymap::Theme.dark
      )

      svg = renderer.render([])

      expect(rects_in(svg)).to be_empty
    end

    it "draws the background of the theme behind the sky" do
      canvas = Skymap::Canvas.new(size: 400, padding: 20)
      theme = Skymap::Theme.light.with(background: "#fafafa")
      renderer = described_class.new(canvas: canvas, theme: theme)

      svg = renderer.render([])
      background = REXML::Document.new(svg).root.elements.first

      expect(rects_in(svg).size).to eq(1)
      expect(background.name).to eq("rect")
      expect(background["x"]).to eq("0")
      expect(background["y"]).to eq("0")
      expect(background["width"]).to eq("400")
      expect(background["height"]).to eq("400")
      expect(background["fill"]).to eq("#fafafa")
    end

    it "leaves everything unpainted when every color of the theme is none" do
      canvas = Skymap::Canvas.new(size: 400, padding: 20)
      colors = Skymap::Theme.dark.to_h.except(:moon_shadow_opacity, :font)
      theme = Skymap::Theme.dark.with(**colors.transform_values { "none" })
      renderer = described_class.new(canvas: canvas, theme: theme)

      svg = renderer.render(one_of_each_element)
      painted = REXML::Document.new(svg).root.elements.flat_map do |element|
        %w[fill stroke].filter_map { |attribute| element[attribute] }
      end

      expect(painted).not_to be_empty
      expect(painted.uniq).to eq(["none"])
    end

    it "rounds the sky geometry to 2 decimals" do
      canvas = Skymap::Canvas.new(size: 401, padding: 1.3333)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)

      svg = renderer.render([])
      sky = circles_in(svg).first

      expect(sky["cx"]).to eq("200.5")
      expect(sky["cy"]).to eq("200.5")
      expect(sky["r"]).to eq("199.17")
    end

    it "draws a star on top of the sky for each dot" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
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
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
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

    it "draws a planet as a tinted disk" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
      planet = Skymap::Renderer::Planet.new(
        center: point(100.123, 150.456),
        radius: 3.456
      )

      svg = renderer.render([planet])
      _sky, drawn = circles_in(svg)

      expect(drawn["cx"]).to eq("100.12")
      expect(drawn["cy"]).to eq("150.46")
      expect(drawn["r"]).to eq("3.46")
      expect(drawn["fill"]).to eq("#ffe6b3")
    end

    it "draws the Sun as a golden disk" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
      sun = Skymap::Renderer::Sun.new(
        center: point(100.123, 150.456),
        radius: 6.789
      )

      svg = renderer.render([sun])
      _sky, drawn = circles_in(svg)

      expect(drawn["cx"]).to eq("100.12")
      expect(drawn["cy"]).to eq("150.46")
      expect(drawn["r"]).to eq("6.79")
      expect(drawn["fill"]).to eq("#ffd34d")
    end

    it "draws the name of a constellation as centered text" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
      caption = Skymap::Renderer::Caption.new(
        position: point(100.123, 150.456),
        text: "Ursa Minor",
        size: 11.678,
        kind: :constellation
      )

      svg = renderer.render([caption])
      drawn = texts_in(svg).first

      expect(drawn.text.strip).to eq("Ursa Minor")
      expect(drawn["x"]).to eq("100.12")
      expect(drawn["y"]).to eq("150.46")
      expect(drawn["font-size"]).to eq("11.68")
      expect(drawn["text-anchor"]).to eq("middle")
      expect(drawn["fill"]).to eq("#6f8fc2")
    end

    it "draws the name of a star with the tint of the star names" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
      caption = Skymap::Renderer::Caption.new(
        position: point(100, 150),
        text: "Sirius",
        size: 10,
        kind: :star
      )

      svg = renderer.render([caption])
      drawn = texts_in(svg).first

      expect(drawn["fill"]).to eq("#a8b8d0")
    end

    it "draws the name of a planet with the tint of the planets" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
      caption = Skymap::Renderer::Caption.new(
        position: point(100, 150),
        text: "Saturn",
        size: 10,
        kind: :planet
      )

      svg = renderer.render([caption])
      drawn = texts_in(svg).first

      expect(drawn["fill"]).to eq("#ffe6b3")
    end

    it "draws each label as centered text" do
      canvas = Skymap::Canvas.new(size: 400, padding: 20)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
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
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
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
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
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
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
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
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
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

    it "draws the ecliptic as a solid polyline" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
      ecliptic = Skymap::Renderer::Ecliptic.new(
        points: [point(100, 150), point(120.256, 180.004), point(250, 300)],
        width: 1.5
      )

      svg = renderer.render([ecliptic])
      drawn = polylines_in(svg).first

      expect(drawn["points"]).to eq("100,150 120.26,180.0 250,300")
      expect(drawn["fill"]).to eq("none")
      expect(drawn["stroke"]).to eq("#8c7a3a")
      expect(drawn["stroke-width"]).to eq("1.5")
      expect(drawn["stroke-dasharray"]).to be_nil
    end

    it "draws the Moon as a dark disk with its lit part on top" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
      moon = Skymap::Renderer::Moon.new(
        center: point(100, 100),
        radius: 10,
        illuminated_fraction: 0.75,
        rotation: 30
      )

      svg = renderer.render([moon])
      group = groups_in(svg).first
      shadow, lit = group.elements.to_a

      expect(group["transform"]).to eq("rotate(30 100 100)")
      expect(shadow["r"]).to eq("10")
      expect(shadow["fill"]).to eq("#232a35")
      expect(shadow["fill-opacity"]).to eq("0.6")
      expect(lit["fill"]).to eq("#f1ecd6")
    end

    it "writes a rational shadow opacity as a decimal" do
      canvas = Skymap::Canvas.new(size: 400, padding: 20)
      theme = Skymap::Theme.dark.with(moon_shadow_opacity: Rational(1, 2))
      renderer = described_class.new(canvas: canvas, theme: theme)
      moon = Skymap::Renderer::Moon.new(
        center: point(100, 100),
        radius: 10,
        illuminated_fraction: 0.75,
        rotation: 0
      )

      svg = renderer.render([moon])
      shadow, _lit = groups_in(svg).first.elements.to_a

      expect(shadow["fill-opacity"]).to eq("0.5")
    end

    it "rejects a caption of an unknown kind" do
      canvas = Skymap::Canvas.new(size: 400, padding: 20)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
      caption = Skymap::Renderer::Caption.new(
        position: point(50, 50), text: "Moon", size: 1, kind: :moon
      )

      expect { renderer.render([caption]) }
        .to raise_error(ArgumentError, /unknown caption kind: moon/)
    end

    it "draws a gibbous Moon with a terminator that bulges to the dark side" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
      moon = Skymap::Renderer::Moon.new(
        center: point(100, 100),
        radius: 10,
        illuminated_fraction: 0.75,
        rotation: 0
      )

      svg = renderer.render([moon])
      lit = groups_in(svg).first.elements["path"]

      expect(lit["d"]).to eq(
        "M 100,90 A 10,10 0 0 1 100,110 A 5.0,10 0 0 1 100,90 Z"
      )
    end

    it "draws a crescent Moon with a terminator that bulges to the lit side" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
      moon = Skymap::Renderer::Moon.new(
        center: point(100, 100),
        radius: 10,
        illuminated_fraction: 0.25,
        rotation: 0
      )

      svg = renderer.render([moon])
      lit = groups_in(svg).first.elements["path"]

      expect(lit["d"]).to eq(
        "M 100,90 A 10,10 0 0 1 100,110 A 5.0,10 0 0 0 100,90 Z"
      )
    end

    it "draws a half Moon with a straight terminator" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
      moon = Skymap::Renderer::Moon.new(
        center: point(100, 100),
        radius: 10,
        illuminated_fraction: 0.5,
        rotation: 0
      )

      svg = renderer.render([moon])
      lit = groups_in(svg).first.elements["path"]

      expect(lit["d"]).to eq(
        "M 100,90 A 10,10 0 0 1 100,110 A 0.0,10 0 0 0 100,90 Z"
      )
    end

    it "rounds the Moon geometry to 2 decimals" do
      canvas = Skymap::Canvas.new(size: 400, padding: 1.5)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
      moon = Skymap::Renderer::Moon.new(
        center: point(109.25833333, 59.63552),
        radius: 1.23456,
        illuminated_fraction: 0.5,
        rotation: 12.34567
      )

      svg = renderer.render([moon])
      group = groups_in(svg).first
      shadow = group.elements["circle"]

      expect(group["transform"]).to eq("rotate(12.35 109.26 59.64)")
      expect(shadow["cx"]).to eq("109.26")
      expect(shadow["cy"]).to eq("59.64")
      expect(shadow["r"]).to eq("1.23")
    end

    it "draws elements in the given order, on top of the sky" do
      canvas = Skymap::Canvas.new(size: 400, padding: 20)
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)
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
      renderer = described_class.new(canvas: canvas, theme: Skymap::Theme.dark)

      expect { renderer.render(["N"]) }
        .to raise_error(ArgumentError, "unknown element: String")
    end
  end

  def point(x, y)
    Skymap::Point.new(x: x, y: y)
  end

  def one_of_each_element
    [
      Skymap::Renderer::Boundary.new(
        points: [point(1, 1), point(2, 2)], width: 1
      ),
      Skymap::Renderer::Line.new(from: point(1, 1), to: point(2, 2), width: 1),
      Skymap::Renderer::Ecliptic.new(
        points: [point(1, 1), point(2, 2)], width: 1
      ),
      Skymap::Renderer::Dot.new(center: point(10, 10), radius: 1),
      Skymap::Renderer::Planet.new(center: point(20, 20), radius: 1),
      Skymap::Renderer::Sun.new(center: point(30, 30), radius: 1),
      Skymap::Renderer::Label.new(position: point(40, 40), text: "N", size: 1),
      *%i[constellation star planet].map do |kind|
        Skymap::Renderer::Caption.new(
          position: point(50, 50), text: kind.to_s, size: 1, kind: kind
        )
      end
    ]
  end
end
