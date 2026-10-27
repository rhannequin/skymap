# frozen_string_literal: true

RSpec.describe Skymap::Layers::Sun do
  describe "#elements" do
    it "draws the Sun where it is in the sky" do
      context = Skymap::Context.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 12)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris)

      sun, = layer.elements(context)

      expect(sun.center.x.round(1)).to eq(204.2)
      expect(sun.center.y.round(1)).to eq(291.4)
    end

    it "draws the Sun with a size that follows the canvas" do
      small = Skymap::Context.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 12)),
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      large = Skymap::Context.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 12)),
        canvas: Skymap::Canvas.new(size: 800, padding: 0)
      )
      layer = described_class.new(ephem: ephemeris)

      small_sun, = layer.elements(small)
      large_sun, = layer.elements(large)

      expect(small_sun.radius).to eq(6)
      expect(large_sun.radius).to eq(12)
    end

    it "leaves out the Sun below the horizon" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(ephem: ephemeris)

      suns = layer.elements(context)

      expect(suns).to be_empty
    end
  end
end
