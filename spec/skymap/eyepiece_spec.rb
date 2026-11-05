# frozen_string_literal: true

RSpec.describe Skymap::Eyepiece do
  describe ".new" do
    it "keeps the focal length in millimeters and the apparent field" do
      eyepiece = described_class.new(
        focal_length: 25,
        apparent_field_of_view: 52
      )

      expect(eyepiece.focal_length).to eq(25)
      expect(eyepiece.apparent_field_of_view).to eq(52)
    end

    it "accepts the widest apparent field, 180 degrees" do
      eyepiece = described_class.new(
        focal_length: 25,
        apparent_field_of_view: 180
      )

      expect(eyepiece.apparent_field_of_view).to eq(180)
    end

    it "rejects a focal length of zero" do
      expect {
        described_class.new(focal_length: 0, apparent_field_of_view: 52)
      }.to raise_error(ArgumentError, /focal_length must be/)
    end

    it "rejects a negative focal length" do
      expect {
        described_class.new(focal_length: -25, apparent_field_of_view: 52)
      }.to raise_error(ArgumentError, /focal_length must be/)
    end

    it "rejects a focal length that is not a number" do
      expect {
        described_class.new(focal_length: "25", apparent_field_of_view: 52)
      }.to raise_error(ArgumentError, /focal_length must be/)
    end

    it "rejects an infinite focal length" do
      expect {
        described_class.new(
          focal_length: Float::INFINITY,
          apparent_field_of_view: 52
        )
      }.to raise_error(ArgumentError, /focal_length must be/)
    end

    it "rejects an apparent field of zero" do
      expect {
        described_class.new(focal_length: 25, apparent_field_of_view: 0)
      }.to raise_error(ArgumentError, /apparent_field_of_view must be/)
    end

    it "rejects an apparent field above 180 degrees" do
      expect {
        described_class.new(focal_length: 25, apparent_field_of_view: 181)
      }.to raise_error(ArgumentError, /apparent_field_of_view must be/)
    end

    it "rejects an apparent field that is not a number" do
      expect {
        described_class.new(focal_length: 25, apparent_field_of_view: nil)
      }.to raise_error(ArgumentError, /apparent_field_of_view must be/)
    end
  end
end
