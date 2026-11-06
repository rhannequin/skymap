# frozen_string_literal: true

RSpec.describe Skymap::StarList do
  describe ".wrap" do
    it "wraps a list of stars" do
      stars = [star(right_ascension: 1, declination: 2, magnitude: 3)]

      wrapped = described_class.wrap(stars)

      expect(wrapped).to be_a(described_class)
    end

    it "leaves a catalog as it is" do
      catalog = Skymap::Catalog::Stars.new

      wrapped = described_class.wrap(catalog)

      expect(wrapped).to be(catalog)
    end
  end

  describe "#search" do
    it "gives every star without a limit" do
      bright = star(right_ascension: 1, declination: 2, magnitude: 3)
      faint = star(right_ascension: 4, declination: 5, magnitude: 9)
      list = described_class.new([bright, faint])

      stars = list.search

      expect(stars).to eq([bright, faint])
    end

    it "gives the stars brighter than the magnitude limit" do
      bright = star(right_ascension: 1, declination: 2, magnitude: 3)
      faint = star(right_ascension: 4, declination: 5, magnitude: 9)
      list = described_class.new([bright, faint])

      stars = list.search(magnitude_limit: 3)

      expect(stars).to eq([bright])
    end

    it "gives every star of a list that is not an array" do
      bright = star(right_ascension: 1, declination: 2, magnitude: 3)
      list = described_class.new([bright].each)

      stars = list.search

      expect(stars).to eq([bright])
    end
  end

  describe "#by_hr" do
    it "gives the stars by Harvard Revised number" do
      sirius = star(
        right_ascension: 6.75,
        declination: -16.7,
        magnitude: -1.46,
        hr: 2491
      )
      list = described_class.new([sirius])

      stars = list.by_hr

      expect(stars).to eq(2491 => sirius)
    end
  end
end
