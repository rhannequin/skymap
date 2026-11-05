# frozen_string_literal: true

RSpec.describe Skymap::Setup do
  describe ".new" do
    it "pairs a telescope with an eyepiece" do
      telescope = telescope_of(1200)
      eyepiece = eyepiece_of(25, 52)

      setup = described_class.new(telescope: telescope, eyepiece: eyepiece)

      expect(setup.telescope).to be(telescope)
      expect(setup.eyepiece).to be(eyepiece)
    end

    it "rejects something that is not a telescope" do
      eyepiece = eyepiece_of(25, 52)

      expect { described_class.new(telescope: 1200, eyepiece: eyepiece) }
        .to raise_error(ArgumentError, /telescope must be/)
    end

    it "rejects something that is not an eyepiece" do
      telescope = telescope_of(1200)

      expect { described_class.new(telescope: telescope, eyepiece: 25) }
        .to raise_error(ArgumentError, /eyepiece must be/)
    end
  end

  describe "#magnification" do
    it "divides the focal length of the telescope by the one of the eyepiece" do
      setup = described_class.new(
        telescope: telescope_of(1200),
        eyepiece: eyepiece_of(25, 52)
      )

      expect(setup.magnification).to eq(48.0)
    end

    it "keeps the decimals of a magnification that is not whole" do
      setup = described_class.new(
        telescope: telescope_of(1000),
        eyepiece: eyepiece_of(12, 68)
      )

      expect(setup.magnification).to be_within(1e-9).of(83.3333333333)
    end
  end

  describe "#true_field" do
    it "divides the apparent field of the eyepiece by the magnification" do
      setup = described_class.new(
        telescope: telescope_of(1200),
        eyepiece: eyepiece_of(25, 52)
      )

      expect(setup.true_field.degrees).to be_within(1e-9).of(1.0833333333)
    end

    it "is an angle that a view and the field circles accept" do
      setup = described_class.new(
        telescope: telescope_of(1200),
        eyepiece: eyepiece_of(25, 52)
      )
      center = equatorial(right_ascension: 5.6, declination: 0)

      view = Skymap::View.new(center: center, field_of_view: setup.true_field)

      expect(view.field_of_view).to eq(setup.true_field)
      expect { Skymap::Layers::FieldCircles.new(fields: [setup]) }
        .not_to raise_error
    end

    it "gets narrower with a shorter eyepiece" do
      telescope = telescope_of(1200)
      long = described_class.new(
        telescope: telescope,
        eyepiece: eyepiece_of(25, 52)
      )
      short = described_class.new(
        telescope: telescope,
        eyepiece: eyepiece_of(10, 52)
      )

      expect(short.true_field.radians).to be < long.true_field.radians
    end
  end

  describe "#label" do
    it "gives the eyepiece, the magnification and the true field" do
      setup = described_class.new(
        telescope: telescope_of(1200),
        eyepiece: eyepiece_of(25, 52)
      )

      expect(setup.label).to eq("25 mm, 48×, 1.1°")
    end

    it "keeps the decimals of the focal length of the eyepiece" do
      setup = described_class.new(
        telescope: telescope_of(1200),
        eyepiece: eyepiece_of(12.5, 52)
      )

      expect(setup.label).to start_with("12.5 mm, 96×")
    end

    it "rounds the magnification to a whole number" do
      setup = described_class.new(
        telescope: telescope_of(1000),
        eyepiece: eyepiece_of(12, 68)
      )

      expect(setup.label).to start_with("12 mm, 83×")
    end

    it "writes a whole number of degrees without a decimal" do
      setup = described_class.new(
        telescope: telescope_of(1200),
        eyepiece: eyepiece_of(25, 96)
      )

      expect(setup.label).to end_with(", 2°")
    end

    it "writes exactly one degree as degrees" do
      setup = described_class.new(
        telescope: telescope_of(1200),
        eyepiece: eyepiece_of(25, 48)
      )

      expect(setup.label).to end_with(", 1°")
    end

    it "writes a field that rounds to 60 arcminutes as one degree" do
      setup = described_class.new(
        telescope: telescope_of(1200),
        eyepiece: eyepiece_of(25, 47.76)
      )

      expect(setup.label).to end_with(", 1°")
    end

    it "writes a field just under one degree in arcminutes" do
      setup = described_class.new(
        telescope: telescope_of(1200),
        eyepiece: eyepiece_of(25, 47.52)
      )

      expect(setup.label).to end_with(", 59′")
    end

    it "writes a field of less than a degree in arcminutes" do
      setup = described_class.new(
        telescope: telescope_of(1200),
        eyepiece: eyepiece_of(25, 12)
      )

      expect(setup.label).to end_with(", 15′")
    end

    it "writes a field of less than an arcminute in arcseconds" do
      setup = described_class.new(
        telescope: telescope_of(1200),
        eyepiece: eyepiece_of(25, 0.2)
      )

      expect(setup.label).to end_with(", 15″")
    end
  end

  def telescope_of(focal_length_mm)
    Skymap::Telescope.new(focal_length_mm: focal_length_mm, aperture_mm: 200)
  end

  def eyepiece_of(focal_length_mm, apparent_field_degrees)
    Skymap::Eyepiece.new(
      focal_length_mm: focal_length_mm,
      apparent_field_of_view: Astronoby::Angle.from_degrees(
        apparent_field_degrees
      )
    )
  end
end
