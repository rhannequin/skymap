# frozen_string_literal: true

RSpec.describe Skymap::Eyepiece do
  describe ".new" do
    it "keeps the focal length in millimeters and the apparent field" do
      field = Astronoby::Angle.from_degrees(52)

      eyepiece = described_class.new(
        focal_length_mm: 25,
        apparent_field_of_view: field
      )

      expect(eyepiece.focal_length_mm).to eq(25)
      expect(eyepiece.apparent_field_of_view).to be(field)
    end

    it "accepts an apparent field of exactly 180 degrees" do
      expect {
        described_class.new(
          focal_length_mm: 25,
          apparent_field_of_view: Astronoby::Angle.from_degrees(180)
        )
      }.not_to raise_error
    end

    it "rejects a focal length of zero" do
      expect {
        described_class.new(
          focal_length_mm: 0,
          apparent_field_of_view: Astronoby::Angle.from_degrees(52)
        )
      }.to raise_error(ArgumentError, /focal_length_mm must be/)
    end

    it "rejects a negative focal length" do
      expect {
        described_class.new(
          focal_length_mm: -25,
          apparent_field_of_view: Astronoby::Angle.from_degrees(52)
        )
      }.to raise_error(ArgumentError, /focal_length_mm must be/)
    end

    it "rejects a focal length that is not a number" do
      expect {
        described_class.new(
          focal_length_mm: "25",
          apparent_field_of_view: Astronoby::Angle.from_degrees(52)
        )
      }.to raise_error(ArgumentError, /focal_length_mm must be/)
    end

    it "rejects an infinite focal length" do
      expect {
        described_class.new(
          focal_length_mm: Float::INFINITY,
          apparent_field_of_view: Astronoby::Angle.from_degrees(52)
        )
      }.to raise_error(ArgumentError, /focal_length_mm must be/)
    end

    it "rejects an apparent field of zero" do
      expect {
        described_class.new(
          focal_length_mm: 25,
          apparent_field_of_view: Astronoby::Angle.zero
        )
      }.to raise_error(ArgumentError, /apparent_field_of_view must be/)
    end

    it "rejects an apparent field above 180 degrees" do
      expect {
        described_class.new(
          focal_length_mm: 25,
          apparent_field_of_view: Astronoby::Angle.from_degrees(181)
        )
      }.to raise_error(ArgumentError, /apparent_field_of_view must be/)
    end

    it "rejects an apparent field that is a number of degrees" do
      expect {
        described_class.new(focal_length_mm: 25, apparent_field_of_view: 52)
      }.to raise_error(ArgumentError, /apparent_field_of_view must be/)
    end
  end
end
