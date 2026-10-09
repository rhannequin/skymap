# frozen_string_literal: true

RSpec.describe Skymap::Layers::ConstellationBoundaries do
  describe "#elements" do
    it "draws a boundary through the positions of its points" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      points = [
        equatorial(right_ascension: 3, declination: 30),
        equatorial(right_ascension: 3, declination: 40),
        equatorial(right_ascension: 4, declination: 50)
      ]
      layer = described_class.new(
        boundaries: [constellation_boundary(points: points)]
      )

      expected = points.map do |point|
        horizontal = context.horizontal_coordinates(point)
        context.project(
          altitude: horizontal.altitude,
          azimuth: horizontal.azimuth
        )
      end

      boundary, = layer.elements(context)

      expect(boundary.points).to eq(expected)
    end

    it "leaves out a boundary below the horizon" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      points = [
        equatorial(right_ascension: 3, declination: -30),
        equatorial(right_ascension: 3, declination: -40)
      ]
      layer = described_class.new(
        boundaries: [constellation_boundary(points: points)]
      )

      boundaries = layer.elements(context)

      expect(boundaries).to be_empty
    end

    it "stops a boundary that goes below the horizon at the horizon" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      points = [
        equatorial(right_ascension: 3, declination: 30),
        equatorial(right_ascension: 3, declination: -20)
      ]
      layer = described_class.new(
        boundaries: [constellation_boundary(points: points)]
      )

      boundary, = layer.elements(context)

      expect(boundary.points.size).to eq(2)
      expect(distance_from_center(boundary.points.last)).to eq(198.5)
    end

    it "starts a boundary that comes back above the horizon at the horizon" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      points = [
        equatorial(right_ascension: 3, declination: -20),
        equatorial(right_ascension: 3, declination: 30)
      ]
      layer = described_class.new(
        boundaries: [constellation_boundary(points: points)]
      )

      boundary, = layer.elements(context)

      expect(boundary.points.size).to eq(2)
      expect(distance_from_center(boundary.points.first)).to eq(198.5)
    end

    it "draws a boundary that dips below the horizon in two parts" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      points = [
        equatorial(right_ascension: 3, declination: 30),
        equatorial(right_ascension: 3, declination: -20),
        equatorial(right_ascension: 4, declination: -20),
        equatorial(right_ascension: 4, declination: 30)
      ]
      layer = described_class.new(
        boundaries: [constellation_boundary(points: points)]
      )

      boundaries = layer.elements(context)

      expect(boundaries.size).to eq(2)
    end

    it "draws each boundary on its own" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(
        boundaries: [
          constellation_boundary(
            points: [
              equatorial(right_ascension: 3, declination: 30),
              equatorial(right_ascension: 3, declination: 40)
            ]
          ),
          constellation_boundary(
            points: [
              equatorial(right_ascension: 9, declination: 30),
              equatorial(right_ascension: 9, declination: 40)
            ]
          )
        ]
      )

      boundaries = layer.elements(context)

      expect(boundaries.size).to eq(2)
    end

    it "draws thin boundaries that scale with the canvas" do
      points = [
        equatorial(right_ascension: 3, declination: 30),
        equatorial(right_ascension: 3, declination: 40)
      ]
      layer = described_class.new(
        boundaries: [constellation_boundary(points: points)]
      )
      small = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      large = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 800, padding: 0)
      )

      small_boundary, = layer.elements(small)
      large_boundary, = layer.elements(large)

      expect(small_boundary.width).to be < 1
      expect(large_boundary.width).to eq(small_boundary.width * 2)
    end
  end

  def distance_from_center(point)
    Math.hypot(point.x - 200, point.y - 200).round(2)
  end
end
