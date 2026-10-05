# frozen_string_literal: true

RSpec.describe Skymap::Layers::Stars do
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

      bright_dot, faint_dot = layer.elements(context)

      expect(bright_dot.radius).to be > faint_dot.radius
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
end
