# frozen_string_literal: true

RSpec.describe Skymap::Catalog::ConstellationLines do
  it "loads every line of the IAU constellations" do
    catalog = described_class.new

    count = catalog.count

    expect(count).to eq(752)
  end

  it "reads the constellation, ends and weight of each line" do
    catalog = described_class.new

    line = catalog.find { |line| line.from == [4295] && line.to == [4301] }

    expect(line.constellation).to eq("UMa")
    expect(line.weight).to eq(:bold)
  end

  it "reads an end made of two stars" do
    catalog = described_class.new

    line = catalog.find { |line| line.to == [6020, 6102] }

    expect(line.from).to eq([5470])
  end
end
