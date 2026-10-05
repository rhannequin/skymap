# frozen_string_literal: true

RSpec.describe Skymap::Layers::ConstellationLines do
  describe "#elements" do
    it "draws a line between two stars, from one dot to the other" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      stars = [
        star(hr: 1, right_ascension: 0, declination: 80, magnitude: 2),
        star(hr: 2, right_ascension: 6, declination: 80, magnitude: 2)
      ]
      layer = described_class.new(
        lines: [constellation_line(from: [1], to: [2])],
        stars: stars
      )

      line, = layer.elements(context)
      first, second = Skymap::Layers::Stars.new(stars: stars).elements(context)

      expect(line.from).to eq(first.center)
      expect(line.to).to eq(second.center)
    end

    it "draws whole figures, including stars fainter than magnitude 5" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      stars = [
        star(hr: 1, right_ascension: 0, declination: 80, magnitude: 2),
        star(hr: 2, right_ascension: 6, declination: 80, magnitude: 6)
      ]
      layer = described_class.new(
        lines: [constellation_line(from: [1], to: [2])],
        stars: stars
      )

      lines = layer.elements(context)

      expect(lines.size).to eq(1)
    end

    it "leaves out a line below the horizon" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      stars = [
        star(hr: 1, right_ascension: 0, declination: -80, magnitude: 2),
        star(hr: 2, right_ascension: 6, declination: -80, magnitude: 2)
      ]
      layer = described_class.new(
        lines: [constellation_line(from: [1], to: [2])],
        stars: stars
      )

      lines = layer.elements(context)

      expect(lines).to be_empty
    end

    it "stops a line that goes below the horizon at the horizon" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      stars = [
        star(hr: 1, right_ascension: 3, declination: 30, magnitude: 2),
        star(hr: 2, right_ascension: 3, declination: -20, magnitude: 2)
      ]
      layer = described_class.new(
        lines: [constellation_line(from: [1], to: [2])],
        stars: stars
      )

      line, = layer.elements(context)
      dot, = Skymap::Layers::Stars.new(stars: stars).elements(context)
      end_x, end_y = line.to.x - 200, line.to.y - 200
      dot_x, dot_y = dot.center.x - 200, dot.center.y - 200

      expect(Math.hypot(end_x, end_y).round(2)).to eq(198.5)
      expect(Math.atan2(end_y, end_x).round(6))
        .to eq(Math.atan2(dot_y, dot_x).round(6))
    end

    it "draws a line ending between two stars to their midpoint" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      stars = [
        star(hr: 1, right_ascension: 0, declination: 80, magnitude: 2),
        star(hr: 2, right_ascension: 6, declination: 80, magnitude: 2),
        star(hr: 3, right_ascension: 12, declination: 80, magnitude: 2)
      ]
      layer = described_class.new(
        lines: [constellation_line(from: [1], to: [2, 3])],
        stars: stars
      )

      line, = layer.elements(context)
      _first, second, third =
        Skymap::Layers::Stars.new(stars: stars).elements(context)

      expect(line.to)
        .to eq(Skymap::Point.midpoint([second.center, third.center]))
    end

    it "draws bold lines thicker than thin ones" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      stars = [
        star(hr: 1, right_ascension: 0, declination: 80, magnitude: 2),
        star(hr: 2, right_ascension: 6, declination: 80, magnitude: 2)
      ]
      layer = described_class.new(
        lines: [
          constellation_line(from: [1], to: [2], weight: :bold),
          constellation_line(from: [1], to: [2], weight: :thin)
        ],
        stars: stars
      )

      bold, thin = layer.elements(context)

      expect(bold.width).to be > thin.width
    end

    it "leaves out a line to a star that was not given" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      stars = [star(hr: 1, right_ascension: 0, declination: 80, magnitude: 2)]
      layer = described_class.new(
        lines: [constellation_line(from: [1], to: [2])],
        stars: stars
      )

      lines = layer.elements(context)

      expect(lines).to be_empty
    end
  end
end
