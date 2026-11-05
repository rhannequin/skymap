# frozen_string_literal: true

RSpec.describe Skymap::PrintSize do
  describe ".new" do
    it "accepts millimeters, centimeters and inches" do
      sizes = %i[mm cm in].map do |unit|
        described_class.new(length: 8, unit: unit)
      end

      expect(sizes.map(&:to_s)).to eq(%w[8mm 8cm 8in])
    end

    it "rejects a length that is not above zero" do
      expect { described_class.new(length: 0, unit: :mm) }
        .to raise_error(ArgumentError, /length/)
      expect { described_class.new(length: -5, unit: :mm) }
        .to raise_error(ArgumentError, /length/)
      expect { described_class.new(length: "20", unit: :mm) }
        .to raise_error(ArgumentError, /length/)
      expect { described_class.new(length: Float::INFINITY, unit: :mm) }
        .to raise_error(ArgumentError, /length/)
    end

    it "rejects an unknown unit" do
      expect { described_class.new(length: 20, unit: :px) }
        .to raise_error(ArgumentError, /unit/)
    end
  end

  describe "#to_s" do
    it "writes a whole length without decimals" do
      size = described_class.new(length: 200.0, unit: :mm)

      expect(size.to_s).to eq("200mm")
    end

    it "keeps the decimals of a fractional length" do
      size = described_class.new(length: 7.5, unit: :in)

      expect(size.to_s).to eq("7.5in")
    end
  end

  describe ".paper" do
    it "fits a square in the width of the paper, minus a margin on each side" do
      sizes = %i[a5 a4 a3 letter tabloid].map do |name|
        described_class.paper(name)
      end

      expect(sizes.map(&:to_s))
        .to eq(%w[128mm 190mm 277mm 195.9mm 259.4mm])
    end

    it "accepts a margin in millimeters" do
      size = described_class.paper(:a4, margin: 15)

      expect(size.to_s).to eq("180mm")
    end

    it "accepts no margin" do
      size = described_class.paper(:a4, margin: 0)

      expect(size.to_s).to eq("210mm")
    end

    it "rejects an unknown paper" do
      expect { described_class.paper(:a0) }
        .to raise_error(ArgumentError, /paper/)
    end

    it "rejects a margin that leaves no room" do
      expect { described_class.paper(:a4, margin: -1) }
        .to raise_error(ArgumentError, /margin/)
      expect { described_class.paper(:a4, margin: 105) }
        .to raise_error(ArgumentError, /margin/)
    end
  end
end
