# frozen_string_literal: true

RSpec.describe Skymap::Point do
  describe ".midpoint" do
    it "finds the point halfway between two points" do
      points = [
        described_class.new(x: 10, y: 20),
        described_class.new(x: 30, y: 60)
      ]

      midpoint = described_class.midpoint(points)

      expect(midpoint).to eq(described_class.new(x: 20, y: 40))
    end

    it "finds the point at the center of several points" do
      points = [
        described_class.new(x: 0, y: 0),
        described_class.new(x: 30, y: 0),
        described_class.new(x: 0, y: 30)
      ]

      midpoint = described_class.midpoint(points)

      expect(midpoint).to eq(described_class.new(x: 10, y: 10))
    end
  end
end
