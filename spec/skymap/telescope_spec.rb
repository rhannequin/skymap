# frozen_string_literal: true

RSpec.describe Skymap::Telescope do
  describe ".new" do
    it "keeps the focal length and the aperture in millimeters" do
      telescope = described_class.new(focal_length: 1200, aperture: 200)

      expect(telescope.focal_length).to eq(1200)
      expect(telescope.aperture).to eq(200)
    end

    it "rejects a focal length of zero" do
      expect { described_class.new(focal_length: 0, aperture: 200) }
        .to raise_error(ArgumentError, /focal_length must be/)
    end

    it "rejects a negative focal length" do
      expect { described_class.new(focal_length: -1200, aperture: 200) }
        .to raise_error(ArgumentError, /focal_length must be/)
    end

    it "rejects a focal length that is not a number" do
      expect { described_class.new(focal_length: "1200", aperture: 200) }
        .to raise_error(ArgumentError, /focal_length must be/)
    end

    it "rejects an infinite focal length" do
      expect {
        described_class.new(focal_length: Float::INFINITY, aperture: 200)
      }.to raise_error(ArgumentError, /focal_length must be/)
    end

    it "rejects an aperture of zero" do
      expect { described_class.new(focal_length: 1200, aperture: 0) }
        .to raise_error(ArgumentError, /aperture must be/)
    end

    it "rejects an aperture that is not a real number" do
      expect { described_class.new(focal_length: 1200, aperture: Float::NAN) }
        .to raise_error(ArgumentError, /aperture must be/)
    end
  end

  describe "#magnification" do
    it "divides the focal length of the telescope by the one of the eyepiece" do
      telescope = described_class.new(focal_length: 1200, aperture: 200)
      eyepiece = Skymap::Eyepiece.new(
        focal_length: 25,
        apparent_field_of_view: 52
      )

      magnification = telescope.magnification(eyepiece)

      expect(magnification).to eq(48)
    end

    it "keeps the decimals of a magnification that is not whole" do
      telescope = described_class.new(focal_length: 1000, aperture: 100)
      eyepiece = Skymap::Eyepiece.new(
        focal_length: 12,
        apparent_field_of_view: 68
      )

      magnification = telescope.magnification(eyepiece)

      expect(magnification).to be_within(1e-6).of(83.333333)
    end

    it "rejects something that is not an eyepiece" do
      telescope = described_class.new(focal_length: 1200, aperture: 200)

      expect { telescope.magnification(25) }
        .to raise_error(ArgumentError, /eyepiece must be/)
    end
  end

  describe "#true_field" do
    it "divides the apparent field of the eyepiece by the magnification" do
      telescope = described_class.new(focal_length: 1200, aperture: 200)
      eyepiece = Skymap::Eyepiece.new(
        focal_length: 25,
        apparent_field_of_view: 52
      )

      true_field = telescope.true_field(eyepiece)

      expect(true_field).to be_within(1e-6).of(1.083333)
    end

    it "gets narrower with a shorter eyepiece" do
      telescope = described_class.new(focal_length: 1200, aperture: 200)
      long = Skymap::Eyepiece.new(
        focal_length: 25,
        apparent_field_of_view: 52
      )
      short = Skymap::Eyepiece.new(
        focal_length: 10,
        apparent_field_of_view: 52
      )

      expect(telescope.true_field(short)).to be < telescope.true_field(long)
    end

    it "gives a field of view that a view accepts" do
      telescope = described_class.new(focal_length: 1200, aperture: 200)
      eyepiece = Skymap::Eyepiece.new(
        focal_length: 25,
        apparent_field_of_view: 52
      )
      center = equatorial(right_ascension: 5.6, declination: 0)

      view = Skymap::View.new(
        center: center,
        field_of_view: telescope.true_field(eyepiece)
      )

      expect(view.field_of_view).to be_within(1e-6).of(1.083333)
    end

    it "gives a field that the field circles accept" do
      telescope = described_class.new(focal_length: 1200, aperture: 200)
      eyepiece = Skymap::Eyepiece.new(
        focal_length: 25,
        apparent_field_of_view: 52
      )

      expect {
        Skymap::Layers::FieldCircles.new(
          fields: [telescope.true_field(eyepiece)]
        )
      }.not_to raise_error
    end

    it "rejects something that is not an eyepiece" do
      telescope = described_class.new(focal_length: 1200, aperture: 200)

      expect { telescope.true_field(nil) }
        .to raise_error(ArgumentError, /eyepiece must be/)
    end
  end
end
