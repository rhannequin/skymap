# frozen_string_literal: true

RSpec.describe Skymap::View do
  describe ".new" do
    it "centers on equatorial coordinates" do
      center = equatorial(right_ascension: 5.6, declination: 0)
      field_of_view = Astronoby::Angle.from_degrees(30)

      view = described_class.new(center: center, field_of_view: field_of_view)

      expect(view.center).to be(center)
      expect(view.field_of_view).to eq(field_of_view)
    end

    it "centers on horizontal coordinates" do
      view = view_towards(altitude: 40, azimuth: 180, field_of_view: 30)

      expect(view.center.altitude.degrees).to eq(40)
    end

    it "looks up from the zenith, unturned and not mirrored by default" do
      view = view_towards(altitude: 40, azimuth: 180, field_of_view: 30)

      expect(view.orientation).to eq(:zenith_up)
      expect(view.rotation).to eq(Astronoby::Angle.zero)
      expect(view.mirrored).to be(false)
    end

    it "takes an orientation, a rotation and a mirror" do
      center = equatorial(right_ascension: 5.6, declination: 0)
      rotation = Astronoby::Angle.from_degrees(180)

      view = described_class.new(
        center: center,
        field_of_view: Astronoby::Angle.from_degrees(1),
        orientation: :equatorial,
        rotation: rotation,
        mirrored: true
      )

      expect(view.orientation).to eq(:equatorial)
      expect(view.rotation).to eq(rotation)
      expect(view.mirrored).to be(true)
    end

    it "accepts a field of view of the whole sky" do
      center = equatorial(right_ascension: 5.6, declination: 0)

      view = described_class.new(
        center: center,
        field_of_view: Astronoby::Angle.from_degrees(180)
      )

      expect(view.field_of_view.degrees).to eq(180)
    end

    it "rejects an unknown orientation" do
      center = equatorial(right_ascension: 5.6, declination: 0)

      expect {
        described_class.new(
          center: center,
          field_of_view: Astronoby::Angle.from_degrees(1),
          orientation: :upside_down
        )
      }.to raise_error(ArgumentError, /orientation must be one of/)
    end

    it "rejects a rotation that is a number" do
      center = equatorial(right_ascension: 5.6, declination: 0)

      expect {
        described_class.new(
          center: center,
          field_of_view: Astronoby::Angle.from_degrees(1),
          rotation: 90
        )
      }.to raise_error(ArgumentError, /rotation must be an Astronoby::Angle/)
    end

    it "rejects a rotation that is not finite" do
      center = equatorial(right_ascension: 5.6, declination: 0)

      expect {
        described_class.new(
          center: center,
          field_of_view: Astronoby::Angle.from_degrees(1),
          rotation: Astronoby::Angle.from_radians(Float::NAN)
        )
      }.to raise_error(ArgumentError, /rotation must be/)
    end

    it "rejects a mirror that is not true or false" do
      center = equatorial(right_ascension: 5.6, declination: 0)

      expect {
        described_class.new(
          center: center,
          field_of_view: Astronoby::Angle.from_degrees(1),
          mirrored: 1
        )
      }.to raise_error(ArgumentError, /mirrored must be/)
    end

    it "rejects a center that is not a coordinates object" do
      expect {
        described_class.new(
          center: [5.6, 0],
          field_of_view: Astronoby::Angle.from_degrees(30)
        )
      }.to raise_error(ArgumentError, /center must be/)
    end

    it "rejects a field of view of zero" do
      center = equatorial(right_ascension: 5.6, declination: 0)

      expect {
        described_class.new(
          center: center,
          field_of_view: Astronoby::Angle.zero
        )
      }.to raise_error(ArgumentError, /field_of_view must be/)
    end

    it "rejects a field of view above 180 degrees" do
      center = equatorial(right_ascension: 5.6, declination: 0)

      expect {
        described_class.new(
          center: center,
          field_of_view: Astronoby::Angle.from_degrees(181)
        )
      }.to raise_error(ArgumentError, /field_of_view must be/)
    end

    it "rejects a field of view that is a number" do
      center = equatorial(right_ascension: 5.6, declination: 0)

      expect {
        described_class.new(center: center, field_of_view: 30)
      }.to raise_error(ArgumentError, /field_of_view must be/)
    end
  end
end
