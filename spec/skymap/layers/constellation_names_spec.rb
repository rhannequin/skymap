# frozen_string_literal: true

RSpec.describe Skymap::Layers::ConstellationNames do
  describe "#elements" do
    it "names the constellation in the middle of its stars" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      first = star(right_ascension: 0, declination: 89, magnitude: 2, hr: 1)
      second = star(right_ascension: 6, declination: 80, magnitude: 2, hr: 2)
      line = constellation_line(from: [1], to: [2])
      layer = described_class.new(lines: [line], stars: [first, second])

      caption, = layer.elements(context)

      expect(caption.text).to eq("Ursa Minor")
      expect(caption.kind).to eq(:constellation)
      expect(caption.position).to eq(
        Skymap::Point.midpoint(
          [context.position(first), context.position(second)]
        )
      )
    end

    it "names a constellation once, whatever its number of lines" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      stars = [
        star(right_ascension: 0, declination: 89, magnitude: 2, hr: 1),
        star(right_ascension: 6, declination: 80, magnitude: 2, hr: 2),
        star(right_ascension: 12, declination: 80, magnitude: 2, hr: 3)
      ]
      lines = [
        constellation_line(from: [1], to: [2]),
        constellation_line(from: [2], to: [3])
      ]
      layer = described_class.new(lines: lines, stars: stars)

      captions = layer.elements(context)

      expect(captions.size).to eq(1)
    end

    it "leaves out a constellation below the horizon" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      first = star(right_ascension: 0, declination: -89, magnitude: 2, hr: 1)
      second = star(right_ascension: 6, declination: -80, magnitude: 2, hr: 2)
      line = constellation_line(from: [1], to: [2])
      layer = described_class.new(lines: [line], stars: [first, second])

      captions = layer.elements(context)

      expect(captions).to be_empty
    end

    it "leaves out a constellation with most of its stars below the horizon" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      stars = [
        star(right_ascension: 0, declination: 89, magnitude: 2, hr: 1),
        star(right_ascension: 6, declination: -80, magnitude: 2, hr: 2),
        star(right_ascension: 12, declination: -80, magnitude: 2, hr: 3)
      ]
      lines = [
        constellation_line(from: [1], to: [2]),
        constellation_line(from: [2], to: [3])
      ]
      layer = described_class.new(lines: lines, stars: stars)

      captions = layer.elements(context)

      expect(captions).to be_empty
    end

    it "names a constellation by the stars above the horizon" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      stars = [
        star(right_ascension: 0, declination: 89, magnitude: 2, hr: 1),
        star(right_ascension: 6, declination: 80, magnitude: 2, hr: 2),
        star(right_ascension: 12, declination: -80, magnitude: 2, hr: 3)
      ]
      lines = [
        constellation_line(from: [1], to: [2]),
        constellation_line(from: [2], to: [3])
      ]
      layer = described_class.new(lines: lines, stars: stars)

      caption, = layer.elements(context)

      expect(caption.position).to eq(
        Skymap::Point.midpoint(
          [context.position(stars[0]), context.position(stars[1])]
        )
      )
    end

    it "leaves out a constellation whose stars are not given" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      line = constellation_line(from: [1], to: [2])
      layer = described_class.new(lines: [line], stars: [])

      captions = layer.elements(context)

      expect(captions).to be_empty
    end

    it "draws names with a size that follows the canvas" do
      small = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      large = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 800, padding: 0)
      )
      circumpolar = star(
        right_ascension: 0,
        declination: 89,
        magnitude: 2,
        hr: 1
      )
      line = constellation_line(from: [1], to: [1])
      layer = described_class.new(lines: [line], stars: [circumpolar])

      small_caption, = layer.elements(small)
      large_caption, = layer.elements(large)

      expect(small_caption.size).to be_within(0.001).of(5.6)
      expect(large_caption.size).to be_within(0.001).of(11.2)
    end

    it "names the constellations with the given names" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      circumpolar = star(
        right_ascension: 0,
        declination: 89,
        magnitude: 2,
        hr: 1
      )
      line = constellation_line(from: [1], to: [1])
      layer = described_class.new(
        lines: [line],
        stars: [circumpolar],
        names: {"UMi" => "Petite Ourse"}
      )

      caption, = layer.elements(context)

      expect(caption.text).to eq("Petite Ourse")
    end

    it "leaves out a constellation without a name" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      circumpolar = star(
        right_ascension: 0,
        declination: 89,
        magnitude: 2,
        hr: 1
      )
      line = constellation_line(from: [1], to: [1])
      layer = described_class.new(
        lines: [line],
        stars: [circumpolar],
        names: {}
      )

      captions = layer.elements(context)

      expect(captions).to be_empty
    end
  end
end
