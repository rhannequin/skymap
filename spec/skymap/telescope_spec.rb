# frozen_string_literal: true

RSpec.describe Skymap::Telescope do
  describe ".new" do
    it "keeps the focal length and the aperture in millimeters" do
      telescope = described_class.new(focal_length_mm: 1200, aperture_mm: 200)

      expect(telescope.focal_length_mm).to eq(1200)
      expect(telescope.aperture_mm).to eq(200)
    end

    it "rejects a focal length of zero" do
      expect { described_class.new(focal_length_mm: 0, aperture_mm: 200) }
        .to raise_error(ArgumentError, /focal_length_mm must be/)
    end

    it "rejects a negative focal length" do
      expect { described_class.new(focal_length_mm: -1200, aperture_mm: 200) }
        .to raise_error(ArgumentError, /focal_length_mm must be/)
    end

    it "rejects a focal length that is not a number" do
      expect { described_class.new(focal_length_mm: "1200", aperture_mm: 200) }
        .to raise_error(ArgumentError, /focal_length_mm must be/)
    end

    it "rejects an infinite focal length" do
      expect {
        described_class.new(focal_length_mm: Float::INFINITY, aperture_mm: 200)
      }.to raise_error(ArgumentError, /focal_length_mm must be/)
    end

    it "rejects an aperture of zero" do
      expect { described_class.new(focal_length_mm: 1200, aperture_mm: 0) }
        .to raise_error(ArgumentError, /aperture_mm must be/)
    end

    it "rejects an aperture that is not a real number" do
      expect {
        described_class.new(focal_length_mm: 1200, aperture_mm: Float::NAN)
      }.to raise_error(ArgumentError, /aperture_mm must be/)
    end
  end
end
