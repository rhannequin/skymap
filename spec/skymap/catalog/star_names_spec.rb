# frozen_string_literal: true

RSpec.describe Skymap::Catalog::StarNames do
  describe "#[]" do
    it "gives the name of a star from its Harvard Revised number" do
      names = described_class.new

      name = names[2491]

      expect(name).to eq("Sirius")
    end

    it "gives the names with several words whole" do
      names = described_class.new

      name = names[7228]

      expect(name).to eq("Polaris Australis")
    end

    it "gives nothing for a star without a name" do
      names = described_class.new

      name = names[1]

      expect(name).to be_nil
    end
  end
end
