# frozen_string_literal: true

RSpec.describe Skymap::Canvas do
  describe ".new" do
    it "accepts no padding" do
      canvas = described_class.new(size: 400, padding: 0)

      expect(canvas.radius).to eq(200)
    end

    it "rejects a negative padding" do
      expect { described_class.new(size: 400, padding: -1) }
        .to raise_error(ArgumentError, /padding/)
    end

    it "rejects a padding that leaves no room for the sky" do
      expect { described_class.new(size: 400, padding: 200) }
        .to raise_error(ArgumentError, /padding/)
    end
  end

  describe "#center" do
    it "is the middle of the canvas" do
      canvas = described_class.new(size: 400, padding: 1.5)

      expect(canvas.center).to eq(Skymap::Point.new(x: 200, y: 200))
    end
  end

  describe "#radius" do
    it "fills the canvas minus the padding" do
      canvas = described_class.new(size: 400, padding: 1.5)

      expect(canvas.radius).to eq(198.5)
    end
  end
end
