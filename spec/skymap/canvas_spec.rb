# frozen_string_literal: true

RSpec.describe Skymap::Canvas do
  describe ".new" do
    it "rejects a size that is not a number" do
      expect { described_class.new(size: "400", padding: 0) }
        .to raise_error(ArgumentError, /size/)
      expect { described_class.new(size: nil, padding: 0) }
        .to raise_error(ArgumentError, /size/)
    end

    it "rejects a size that is not above 0" do
      expect { described_class.new(size: 0, padding: 0) }
        .to raise_error(ArgumentError, /size/)
      expect { described_class.new(size: -400, padding: 0) }
        .to raise_error(ArgumentError, /size/)
    end

    it "rejects a size that is not finite" do
      expect { described_class.new(size: Float::INFINITY, padding: 0) }
        .to raise_error(ArgumentError, /size/)
    end

    it "rejects a padding that is not a number" do
      expect { described_class.new(size: 400, padding: "10") }
        .to raise_error(ArgumentError, /padding/)
    end

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

  describe "#print_size" do
    it "is nothing by default" do
      canvas = described_class.new(size: 400, padding: 1.5)

      expect(canvas.print_size).to be_nil
    end

    it "is the physical size the canvas is printed at" do
      size = Skymap::PrintSize.new(length: 200, unit: :mm)
      canvas = described_class.new(size: 400, padding: 1.5, print_size: size)

      expect(canvas.print_size).to eq(size)
    end

    it "rejects anything that is not a print size" do
      expect {
        described_class.new(size: 400, padding: 1.5, print_size: "200mm")
      }.to raise_error(ArgumentError, /print_size/)
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
