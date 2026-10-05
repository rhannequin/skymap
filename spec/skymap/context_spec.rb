# frozen_string_literal: true

RSpec.describe Skymap::Context do
  describe "#horizontal" do
    it "computes the position of a point of the sky once" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      polaris = star(right_ascension: 2.53, declination: 89.26, magnitude: 2)
      same_polaris = star(
        right_ascension: 2.53,
        declination: 89.26,
        magnitude: 2
      )

      first = context.horizontal(polaris)
      second = context.horizontal(same_polaris)

      expect(second).to be(first)
    end
  end

  describe "#position" do
    it "places a star on the canvas where its position projects" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      polaris = star(right_ascension: 2.53, declination: 89.26, magnitude: 2)
      horizontal = context.horizontal(polaris)

      position = context.position(polaris)

      expect(position).to eq(
        context.project(
          altitude: horizontal.altitude,
          azimuth: horizontal.azimuth
        )
      )
    end
  end

  describe "#project" do
    it "projects the horizon on the edge of the sky" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 20)
      )

      point = context.project(
        altitude: Astronoby::Angle.zero,
        azimuth: Astronoby::Angle.zero
      )

      expect(point).to eq(Skymap::Point.new(x: 200, y: 20))
    end

    it "projects the horizon on a circle of the given radius" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 20)
      )

      point = context.project(
        altitude: Astronoby::Angle.zero,
        azimuth: Astronoby::Angle.zero,
        radius: 190
      )

      expect(point).to eq(Skymap::Point.new(x: 200, y: 10))
    end
  end
end
