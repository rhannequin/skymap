# frozen_string_literal: true

RSpec.describe Skymap::Field do
  describe ".new" do
    it "keeps the true field and the label" do
      angle = Astronoby::Angle.from_degrees(5)

      field = described_class.new(true_field: angle, label: "Finder 5°")

      expect(field.true_field).to be(angle)
      expect(field.label).to eq("Finder 5°")
    end

    it "accepts a true field of exactly 180 degrees" do
      expect {
        described_class.new(
          true_field: Astronoby::Angle.from_degrees(180),
          label: "Sky"
        )
      }.not_to raise_error
    end

    it "rejects a true field that is a number of degrees" do
      expect { described_class.new(true_field: 5, label: "Finder") }
        .to raise_error(ArgumentError, /true_field must be/)
    end

    it "rejects a true field of zero" do
      expect {
        described_class.new(true_field: Astronoby::Angle.zero, label: "Finder")
      }.to raise_error(ArgumentError, /true_field must be/)
    end

    it "rejects a negative true field" do
      expect {
        described_class.new(
          true_field: Astronoby::Angle.from_degrees(-5),
          label: "Finder"
        )
      }.to raise_error(ArgumentError, /true_field must be/)
    end

    it "rejects a true field above 180 degrees" do
      expect {
        described_class.new(
          true_field: Astronoby::Angle.from_degrees(181),
          label: "Finder"
        )
      }.to raise_error(ArgumentError, /true_field must be/)
    end

    it "rejects a label that is not a string" do
      expect {
        described_class.new(
          true_field: Astronoby::Angle.from_degrees(5),
          label: :finder
        )
      }.to raise_error(ArgumentError, /label must be/)
    end

    it "rejects a blank label" do
      expect {
        described_class.new(
          true_field: Astronoby::Angle.from_degrees(5),
          label: "  "
        )
      }.to raise_error(ArgumentError, /label must be/)
    end
  end
end
