# frozen_string_literal: true

RSpec.describe Skymap::StarSize do
  describe "#radius" do
    it "gives the brightest magnitude the largest radius" do
      star_size = described_class.new(
        brightest_magnitude: -1.5,
        faintest_magnitude: 6.5,
        min_radius: 0.5,
        max_radius: 4.5,
        exponent: 2
      )

      radius = star_size.radius(-1.5)

      expect(radius).to eq(4.5)
    end

    it "gives the faintest magnitude the smallest radius" do
      star_size = described_class.new(
        brightest_magnitude: -1.5,
        faintest_magnitude: 6.5,
        min_radius: 0.5,
        max_radius: 4.5,
        exponent: 2
      )

      radius = star_size.radius(6.5)

      expect(radius).to eq(0.5)
    end

    it "grows faster as stars get brighter" do
      star_size = described_class.new(
        brightest_magnitude: -1.5,
        faintest_magnitude: 6.5,
        min_radius: 0.5,
        max_radius: 4.5,
        exponent: 2
      )

      radii = [6.5, 5.5, 4.5].map { |magnitude| star_size.radius(magnitude) }

      expect(radii).to eq([0.5, 0.5625, 0.75])
    end

    it "does not grow past the largest radius for brighter magnitudes" do
      star_size = described_class.new(
        brightest_magnitude: -1.5,
        faintest_magnitude: 6.5,
        min_radius: 0.5,
        max_radius: 4.5,
        exponent: 2
      )

      radius = star_size.radius(-4.6)

      expect(radius).to eq(4.5)
    end

    it "does not shrink past the smallest radius for fainter magnitudes" do
      star_size = described_class.new(
        brightest_magnitude: -1.5,
        faintest_magnitude: 6.5,
        min_radius: 0.5,
        max_radius: 4.5,
        exponent: 2
      )

      radius = star_size.radius(8)

      expect(radius).to eq(0.5)
    end

    it "works with whole-number magnitudes and radii" do
      star_size = described_class.new(
        brightest_magnitude: -1,
        faintest_magnitude: 6,
        min_radius: 1,
        max_radius: 5,
        exponent: 2
      )

      radius = star_size.radius(2)

      expect(radius.round(2)).to eq(2.31)
    end
  end
end
