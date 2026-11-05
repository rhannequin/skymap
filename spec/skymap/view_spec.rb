# frozen_string_literal: true

RSpec.describe Skymap::View do
  describe ".new" do
    it "centers on equatorial coordinates" do
      center = equatorial(right_ascension: 5.6, declination: 0)

      view = described_class.new(center: center, field_of_view: 30)

      expect(view.center).to be(center)
      expect(view.field_of_view).to eq(30)
    end

    it "centers on horizontal coordinates" do
      view = view_towards(altitude: 40, azimuth: 180, field_of_view: 30)

      expect(view.center.altitude.degrees).to eq(40)
    end

    it "rejects a center that is not a coordinates object" do
      expect { described_class.new(center: [5.6, 0], field_of_view: 30) }
        .to raise_error(ArgumentError, /center must be/)
    end

    it "rejects a field of view of zero" do
      center = equatorial(right_ascension: 5.6, declination: 0)

      expect { described_class.new(center: center, field_of_view: 0) }
        .to raise_error(ArgumentError, /field_of_view must be/)
    end

    it "rejects a field of view above 180 degrees" do
      center = equatorial(right_ascension: 5.6, declination: 0)

      expect { described_class.new(center: center, field_of_view: 181) }
        .to raise_error(ArgumentError, /field_of_view must be/)
    end

    it "rejects a field of view that is not a number" do
      center = equatorial(right_ascension: 5.6, declination: 0)

      expect { described_class.new(center: center, field_of_view: "30") }
        .to raise_error(ArgumentError, /field_of_view must be/)
    end
  end
end
