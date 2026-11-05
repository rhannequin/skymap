# frozen_string_literal: true

RSpec.describe Skymap::Vector do
  describe ".dot" do
    it "multiplies the components and adds them" do
      expect(described_class.dot([1, 2, 3], [4, 5, 6])).to eq(32)
    end
  end

  describe ".cross" do
    it "gives the vector perpendicular to both" do
      expect(described_class.cross([1, 0, 0], [0, 1, 0])).to eq([0, 0, 1])
    end
  end

  describe ".normalize" do
    it "gives a vector of length 1 in the same direction" do
      expect(described_class.normalize([0.0, 3.0, 4.0])).to eq([0.0, 0.6, 0.8])
    end
  end

  describe ".away_from" do
    it "removes the part of a reference that goes along the other vector" do
      result = described_class.away_from([1.0, 1.0, 0.0], [1.0, 0.0, 0.0])

      expect(result).to eq([0.0, 1.0, 0.0])
    end
  end

  describe ".up_from" do
    it "points to the zenith from a direction in the horizon" do
      up = described_class.up_from([1.0, 0.0, 0.0], 0.9)

      expect(up).to eq([0.0, 0.0, 1.0])
    end

    it "points to the north from a direction at the zenith" do
      up = described_class.up_from([0.0, 0.0, 1.0], 0.9)

      expect(up).to eq([1.0, 0.0, 0.0])
    end

    it "points to the north when the zenith is within the cosine given" do
      forward = [Math.sin(0.1), 0.0, Math.cos(0.1)]

      up = described_class.up_from(forward, Math.cos(0.2))

      expect(up[0]).to be_within(1e-12).of(Math.cos(0.1))
      expect(up[2]).to be_within(1e-12).of(-Math.sin(0.1))
    end
  end
end
