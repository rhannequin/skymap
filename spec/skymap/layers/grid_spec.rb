# frozen_string_literal: true

RSpec.describe Skymap::Layers::Grid do
  describe "#elements" do
    it "draws the circles of declination around the celestial pole" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new

      grids = layer.elements(context)
      circles = grids.select { |grid| grid.points.first == grid.points.last }
      radii = circles.map { |circle|
        circle.points.sum { |point| distance_from_center(point) } /
          circle.points.size
      }

      expect(radii).to include(be_within(1).of(53.19), be_within(1).of(114.6))
    end

    it "draws a line of right ascension every step" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )

      default = described_class.new.elements(context)
      quarters = described_class.new(step: 90).elements(context)
      fine = described_class.new(step: 15).elements(context)

      expect([default, quarters, fine].map { |grids| at_the_pole(grids) })
        .to eq([12, 4, 24])
    end

    it "stops the lines at the horizon" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new

      distances = layer.elements(context).flat_map do |grid|
        grid.points.map { |point| distance_from_center(point) }
      end

      expect(distances.max).to eq(198.5)
    end

    it "draws a parallel that crosses the horizon as one line" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      layer = described_class.new(step: 90)

      grids = layer.elements(context)
      starts = grids.map { |grid| grid.points.first }
      ends = grids.map { |grid| grid.points.last }

      expect(starts & ends).to be_empty
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

      small_grid, = layer.elements(small)
      large_grid, = layer.elements(large)

      expect(small_grid.width).to be < 1
      expect(large_grid.width).to eq(small_grid.width * 2)
    end
  end

  describe "#elements with an epoch" do
    it "draws the same lines by default as with the J2000 epoch" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )

      default = described_class.new.elements(context)
      j2000 = described_class.new(epoch: :j2000).elements(context)

      expect(default.map(&:points)).to eq(j2000.map(&:points))
    end

    it "centers the circles of declination on the pole of date" do
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )

      of_date = circle_distances(
        described_class.new(epoch: :of_date).elements(context)
      )
      j2000 = circle_distances(described_class.new.elements(context))

      expect(of_date.max - of_date.min).to be < 0.01
      expect(j2000.max - j2000.min).to be > 0.5
    end

    it "draws the same number of lines as with J2000" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )

      of_date = described_class.new(epoch: :of_date).elements(context)
      j2000 = described_class.new.elements(context)

      expect(of_date.size).to eq(j2000.size)
    end

    it "draws the lines of date in a zoomed view" do
      view = view_towards(altitude: 48.8575, azimuth: 0, field_of_view: 20)
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view
      )

      grids = described_class.new(step: 5, epoch: :of_date).elements(context)

      expect(grids).not_to be_empty
    end
  end

  describe ".new" do
    it "rejects an unknown epoch" do
      expect { described_class.new(epoch: :b1950) }
        .to raise_error(ArgumentError, /epoch must be :j2000 or :of_date/)
    end

    it "rejects an epoch that is not a symbol" do
      expect { described_class.new(epoch: "of_date") }
        .to raise_error(ArgumentError, /epoch must be/)
    end

    it "rejects a step that is not a whole number of degrees" do
      expect { described_class.new(step: 7.5) }
        .to raise_error(ArgumentError, /step must be a whole number/)
    end

    it "rejects a step that does not divide the circle" do
      expect { described_class.new(step: 7) }
        .to raise_error(ArgumentError, /divides 360/)
    end

    it "rejects a step of zero" do
      expect { described_class.new(step: 0) }
        .to raise_error(ArgumentError, /between 1 and 90/)
    end

    it "rejects a step above 90 degrees" do
      expect { described_class.new(step: 120) }
        .to raise_error(ArgumentError, /between 1 and 90/)
    end
  end

  def circle_distances(grids)
    circle = grids.find { |grid| grid.points.first == grid.points.last }

    circle.points.map { |point| distance_from_center(point) }
  end

  def at_the_pole(grids)
    grids.count do |grid|
      grid.points.any? { |point| distance_from_center(point) < 2 }
    end
  end
end
