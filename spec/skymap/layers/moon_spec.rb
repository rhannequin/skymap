# frozen_string_literal: true

RSpec.describe Skymap::Layers::Moon do
  describe "#elements" do
    it "draws the Moon where it is in the sky" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris)

      moon, = layer.elements(context)

      expect(moon.center.x.round(1)).to eq(183.4)
      expect(moon.center.y.round(1)).to eq(306.5)
    end

    it "lights the part of the Moon that faces the Sun" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris)

      moon, = layer.elements(context)

      expect(moon.illuminated_fraction.round(3)).to eq(0.964)
    end

    it "tilts the lit side of the Moon as it looks from the ground" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris)

      moon, = layer.elements(context)

      expect((moon.rotation % 360).round).to eq(14)
    end

    it "turns the Moon with the sky, not with the chart" do
      observer = Astronoby::Observer.new(
        latitude: Astronoby::Angle.from_degrees(48.8575),
        longitude: Astronoby::Angle.from_degrees(2.3514)
      )
      context = Skymap::Context.new(
        observer: observer,
        instant: Astronoby::Instant.from_time(Time.utc(2026, 10, 3, 3)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris)

      moon, = layer.elements(context)

      expect((moon.rotation % 360).round).to eq(136)
    end

    it "draws the Moon with a size that follows the canvas" do
      small = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      large = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 800, padding: 0)
      )
      layer = described_class.new(ephem: ephemeris)

      small_moon, = layer.elements(small)
      large_moon, = layer.elements(large)

      expect(small_moon.radius).to eq(6)
      expect(large_moon.radius).to eq(12)
    end

    it "leaves out the Moon below the horizon" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris)

      moons = layer.elements(context)

      expect(moons).to be_empty
    end
  end
end
