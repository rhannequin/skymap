# frozen_string_literal: true

RSpec.describe Skymap::Star do
  describe ".by_hr" do
    it "gives each star under its Harvard Revised number" do
      sirius = star(
        right_ascension: 6.75,
        declination: -16.7,
        magnitude: -1.46,
        hr: 2491
      )
      vega = star(
        right_ascension: 18.6,
        declination: 38.8,
        magnitude: 0.03,
        hr: 7001
      )

      stars = described_class.by_hr([sirius, vega])

      expect(stars).to eq(2491 => sirius, 7001 => vega)
    end
  end
end
