# frozen_string_literal: true

RSpec.describe Skymap::Geometry do
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

  describe ".frame" do
    it "gives three perpendicular unit vectors starting with the direction" do
      forward = described_class.normalize([1.0, 2.0, 2.0])

      frame = described_class.frame(forward)

      expect(frame.first).to eq(forward)
      frame.combination(2).each do |a, b|
        expect(described_class.dot(a, b)).to be_within(1e-12).of(0)
      end
      frame.each do |vector|
        expect(described_class.dot(vector, vector)).to be_within(1e-12).of(1)
      end
    end

    it "is right-handed" do
      forward, side, up = described_class.frame([0.0, 0.0, 1.0])

      expect(described_class.cross(side, up)).to eq(forward)
    end

    it "works along an axis" do
      forward, side, up = described_class.frame([1.0, 0.0, 0.0])

      expect(forward).to eq([1.0, 0.0, 0.0])
      expect(described_class.dot(side, up)).to eq(0)
      expect(described_class.dot(side, forward)).to eq(0)
    end
  end
end
