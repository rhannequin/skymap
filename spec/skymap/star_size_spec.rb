# frozen_string_literal: true

RSpec.describe Skymap::StarSize do
  describe "#radius" do
    it "gives the brightest magnitude the largest radius" do
      star_size = described_class.new(
        brightest_magnitude: -1.5,
        faintest_magnitude: 6.5,
        min_radius: 0.5,
        max_radius: 4.5
      )

      radius = star_size.radius(-1.5)

      expect(radius).to eq(4.5)
    end

    it "gives the faintest magnitude the smallest radius" do
      star_size = described_class.new(
        brightest_magnitude: -1.5,
        faintest_magnitude: 6.5,
        min_radius: 0.5,
        max_radius: 4.5
      )

      radius = star_size.radius(6.5)

      expect(radius).to eq(0.5)
    end

    it "grows by the same amount for each step of magnitude" do
      star_size = described_class.new(
        brightest_magnitude: -1.5,
        faintest_magnitude: 6.5,
        min_radius: 0.5,
        max_radius: 4.5
      )

      radii = [6.5, 5.5, 4.5].map { |magnitude| star_size.radius(magnitude) }

      expect(radii).to eq([0.5, 1.0, 1.5])
    end

    it "does not grow past the largest radius for brighter magnitudes" do
      star_size = described_class.new(
        brightest_magnitude: -1.5,
        faintest_magnitude: 6.5,
        min_radius: 0.5,
        max_radius: 4.5
      )

      radius = star_size.radius(-4.6)

      expect(radius).to eq(4.5)
    end

    it "does not shrink past the smallest radius for fainter magnitudes" do
      star_size = described_class.new(
        brightest_magnitude: -1.5,
        faintest_magnitude: 6.5,
        min_radius: 0.5,
        max_radius: 4.5
      )

      radius = star_size.radius(8)

      expect(radius).to eq(0.5)
    end
  end
end
