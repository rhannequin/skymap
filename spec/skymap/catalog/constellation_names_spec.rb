# frozen_string_literal: true

RSpec.describe Skymap::Catalog::ConstellationNames do
  describe "#[]" do
    it "gives the name of a constellation from its abbreviation" do
      names = described_class.new

      name = names["UMa"]

      expect(name).to eq("Ursa Major")
    end

    it "keeps the accents of the names" do
      names = described_class.new

      name = names["Boo"]

      expect(name).to eq("Boötes")
    end

    it "names every constellation of the boundaries" do
      names = described_class.new
      boundaries = Skymap::Catalog::ConstellationBoundaries.new

      abbreviations = boundaries.flat_map(&:constellations).uniq
      named = abbreviations.map { |abbreviation| names[abbreviation] }

      expect(abbreviations.size).to eq(88)
      expect(named).to all(be)
    end

    it "gives nothing for an unknown constellation" do
      names = described_class.new

      name = names["Xyz"]

      expect(name).to be_nil
    end
  end
end
