# frozen_string_literal: true

RSpec.describe Skymap::Layers::Planets do
  describe "#elements" do
    it "draws a planet where it is in the sky" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris)

      saturn, = layer.elements(context)

      expect(saturn.center.x.round(1)).to eq(120.3)
      expect(saturn.center.y.round(1)).to eq(272.4)
    end

    it "leaves out the planets below the horizon" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris, magnitude_limit: 8)

      planets = layer.elements(context)

      expect(planets.size).to eq(3)
    end

    it "leaves out planets fainter than magnitude 5 by default" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris)

      planets = layer.elements(context)

      expect(planets.size).to eq(1)
    end

    it "leaves out planets fainter than the given magnitude limit" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris, magnitude_limit: 6)

      planets = layer.elements(context)

      expect(planets.size).to eq(2)
    end

    it "draws brighter planets bigger" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris, magnitude_limit: 6)

      saturn, uranus = layer.elements(context)

      expect(saturn.radius).to be > uranus.radius
    end

    it "draws planets with a size that follows the canvas" do
      small = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      large = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 800, padding: 0)
      )
      layer = described_class.new(ephem: ephemeris)

      small_saturn, = layer.elements(small)
      large_saturn, = layer.elements(large)

      expect(large_saturn.radius).to eq(small_saturn.radius * 2)
    end

    it "does not name the planets by default" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris)

      elements = layer.elements(context)

      expect(elements.map(&:class)).to eq([Skymap::Renderer::Planet])
    end

    it "names a planet in the lower half of the map above it" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      layer = described_class.new(ephem: ephemeris, labels: true)

      saturn, caption = layer.elements(context)

      expect(caption.text).to eq("Saturn")
      expect(caption.kind).to eq(:planet)
      expect(caption.size).to be_within(0.001).of(5.6)
      expect(caption.position.x).to eq(saturn.center.x)
      expect(caption.position.y).to be_within(0.001).of(
        saturn.center.y - saturn.radius - caption.size
      )
    end

    it "names a planet in the upper half of the map under it" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      layer = described_class.new(
        ephem: ephemeris,
        magnitude_limit: 6,
        labels: true
      )

      _saturn, _saturn_name, uranus, caption = layer.elements(context)

      expect(caption.text).to eq("Uranus")
      expect(caption.position.y).to be_within(0.001).of(
        uranus.center.y + uranus.radius + caption.size
      )
    end

    it "names the planets with the given names" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      layer = described_class.new(
        ephem: ephemeris,
        labels: true,
        names: {saturn: "Saturne"}
      )

      _saturn, caption = layer.elements(context)

      expect(caption.text).to eq("Saturne")
    end

    it "leaves out the name of a planet without one" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      layer = described_class.new(ephem: ephemeris, labels: true, names: {})

      elements = layer.elements(context)

      expect(elements.map(&:class)).to eq([Skymap::Renderer::Planet])
    end
  end
end
