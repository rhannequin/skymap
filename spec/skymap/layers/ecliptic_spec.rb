# frozen_string_literal: true

RSpec.describe Skymap::Layers::Ecliptic do
  describe "#elements" do
    it "draws the line the Sun follows through the sky" do
      context = Skymap::Context.new(
        observer: observer_at(latitude: 48.8575),
        instant: Astronoby::Instant.from_time(Time.utc(2026, 9, 24, 12)),
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      sun, = Skymap::Layers::Sun.new(ephem: ephemeris).elements(context)
      layer = described_class.new

      ecliptic, = layer.elements(context)
      distance = ecliptic.points.each_cons(2).map { |from, to|
        distance_to_segment(sun.center, from, to)
      }.min

      expect(distance).to be < 0.5
    end

    it "stops the ecliptic at the horizon" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new

      distances = layer.elements(context).flat_map do |ecliptic|
        ecliptic.points.map { |point| distance_from_center(point) }
      end

      expect(distances.max).to eq(198.5)
    end

    it "draws a thin line that scales with the canvas" do
      layer = described_class.new
      small = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      large = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 800, padding: 0)
      )

      small_ecliptic, = layer.elements(small)
      large_ecliptic, = layer.elements(large)

      expect(small_ecliptic.width).to be < 1
      expect(large_ecliptic.width).to eq(small_ecliptic.width * 2)
    end
  end

  def distance_from_center(point)
    Math.hypot(point.x - 200, point.y - 200).round(2)
  end

  def distance_to_segment(point, from, to)
    dx = to.x - from.x
    dy = to.y - from.y
    along = ((point.x - from.x) * dx + (point.y - from.y) * dy) /
      (dx * dx + dy * dy)
    along = along.clamp(0, 1)

    Math.hypot(from.x + along * dx - point.x, from.y + along * dy - point.y)
  end
end
