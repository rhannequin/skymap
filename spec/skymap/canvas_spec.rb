# frozen_string_literal: true

RSpec.describe Skymap::Canvas do
  describe "#center_x" do
    it "is the middle of the canvas" do
      canvas = described_class.new(size: 400, padding: 1.5)

      expect(canvas.center_x).to eq(200)
    end
  end

  describe "#center_y" do
    it "is the middle of the canvas" do
      canvas = described_class.new(size: 400, padding: 1.5)

      expect(canvas.center_y).to eq(200)
    end
  end

  describe "#radius" do
    it "fills the canvas minus the padding" do
      canvas = described_class.new(size: 400, padding: 1.5)

      expect(canvas.radius).to eq(198.5)
    end
  end
end
