# frozen_string_literal: true

RSpec.describe Skymap::Layers::Stars do
  describe ".new" do
    it "rejects a magnitude limit that is not a number" do
      expect { described_class.new(stars: [], magnitude_limit: nil) }
        .to raise_error(ArgumentError, /magnitude_limit/)
      expect { described_class.new(stars: [], magnitude_limit: "5") }
        .to raise_error(ArgumentError, /magnitude_limit/)
    end

    it "rejects a magnitude limit that is not finite" do
      expect { described_class.new(stars: [], magnitude_limit: Float::NAN) }
        .to raise_error(ArgumentError, /magnitude_limit/)
    end
  end

  describe "#elements" do
    it "draws a star that never sets" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      circumpolar = star(right_ascension: 0, declination: 89, magnitude: 2)
      layer = described_class.new(stars: [circumpolar])

      dots = layer.elements(context)

      expect(dots.size).to eq(1)
    end

    it "leaves out a star that never rises" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      never_rising = star(right_ascension: 0, declination: -89, magnitude: 2)
      layer = described_class.new(stars: [never_rising])

      dots = layer.elements(context)

      expect(dots).to be_empty
    end

    it "leaves out stars fainter than magnitude 5 by default" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      visible = star(right_ascension: 0, declination: 89, magnitude: 5)
      faint = star(right_ascension: 12, declination: 89, magnitude: 5.1)
      layer = described_class.new(stars: [visible, faint])

      dots = layer.elements(context)

      expect(dots.size).to eq(1)
    end

    it "leaves out stars fainter than the given magnitude limit" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      visible = star(right_ascension: 0, declination: 89, magnitude: 3)
      faint = star(right_ascension: 12, declination: 89, magnitude: 4)
      layer = described_class.new(stars: [visible, faint], magnitude_limit: 3)

      dots = layer.elements(context)

      expect(dots.size).to eq(1)
    end

    it "draws brighter stars bigger" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      bright = star(right_ascension: 0, declination: 89, magnitude: 0)
      faint = star(right_ascension: 12, declination: 89, magnitude: 5)
      layer = described_class.new(stars: [bright, faint])

      faint_dot, bright_dot = layer.elements(context)

      expect(bright_dot.radius).to be > faint_dot.radius
    end

    it "draws the faintest stars first, under the brighter ones" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      bright = star(right_ascension: 0, declination: 89, magnitude: 1)
      middle = star(right_ascension: 6, declination: 89, magnitude: 3)
      faint = star(right_ascension: 12, declination: 89, magnitude: 5)
      layer = described_class.new(stars: [middle, bright, faint])

      dots = layer.elements(context)

      expect(dots.map(&:center)).to eq(
        [faint, middle, bright].map { |star| context.position(star) }
      )
    end

    it "draws stars of the same magnitude in the order they come in" do
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5)
      )
      first = star(right_ascension: 0, declination: 89, magnitude: 3)
      second = star(right_ascension: 6, declination: 89, magnitude: 3)
      layer = described_class.new(stars: [first, second])

      dots = layer.elements(context)

      expect(dots.map(&:center)).to eq(
        [first, second].map { |star| context.position(star) }
      )
    end

    it "scales stars with the size of the sky" do
      small = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 0)
      )
      large = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 800, padding: 0)
      )
      faint = star(right_ascension: 0, declination: 89, magnitude: 5)
      layer = described_class.new(stars: [faint])

      small_dot, = layer.elements(small)
      large_dot, = layer.elements(large)

      expect(small_dot.radius.round(2)).to eq(0.5)
      expect(large_dot.radius.round(2)).to eq(1.0)
    end
  end

  describe "#elements with a view" do
    it "draws the stars in the view only" do
      view = Skymap::View.new(
        center: equatorial(right_ascension: 0, declination: 89),
        field_of_view: Astronoby::Angle.from_degrees(10)
      )
      context = context_at(
        latitude: 90,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view
      )
      near = star(right_ascension: 3, declination: 87, magnitude: 2)
      far = star(right_ascension: 3, declination: 60, magnitude: 2)
      layer = described_class.new(stars: [near, far])

      dots = layer.elements(context)

      expect(dots.map(&:center)).to eq([context.position(near)])
    end

    it "draws the same stars from the catalog as from its whole list" do
      view = Skymap::View.new(
        center: equatorial(right_ascension: 18.6, declination: 38.8),
        field_of_view: Astronoby::Angle.from_degrees(10),
        orientation: :equatorial
      )
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view
      )
      catalog = Skymap::Catalog::Stars.new
      everything = catalog.to_a

      from_catalog = described_class.new(stars: catalog, magnitude_limit: 9)
        .elements(context)
      from_list = described_class.new(stars: everything, magnitude_limit: 9)
        .elements(context)

      expect(from_catalog).not_to be_empty
      expect(from_catalog.map { |dot| [dot.center.x, dot.center.y] }).to eq(
        from_list.map { |dot| [dot.center.x, dot.center.y] }
      )
    end

    it "draws the catalog stars fainter than the Bright Star Catalogue" do
      view = Skymap::View.new(
        center: equatorial(right_ascension: 18.6, declination: 38.8),
        field_of_view: Astronoby::Angle.from_degrees(2),
        orientation: :equatorial
      )
      context = context_at(
        latitude: 48.8575,
        canvas: Skymap::Canvas.new(size: 400, padding: 1.5),
        view: view
      )
      catalog = Skymap::Catalog::Stars.new
      bright = catalog.by_hr.values

      all = described_class.new(stars: catalog, magnitude_limit: 9)
        .elements(context)
      bright_only = described_class.new(stars: bright, magnitude_limit: 9)
        .elements(context)

      expect(bright_only.size).to eq(3)
      expect(all.size).to eq(13)
    end
  end
end
