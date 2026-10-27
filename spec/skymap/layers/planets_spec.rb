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
  end
end
