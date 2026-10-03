# frozen_string_literal: true

RSpec.describe "data/constellations/iau.csv" do
  it "joins stars of the star catalog" do
    lines = Skymap::Catalog::ConstellationLines.new
    stars = Skymap::Catalog::Stars.new.map(&:hr)

    unknown = lines.flat_map { |line| line.from + line.to }.uniq - stars

    expect(unknown).to be_empty
  end

  it "draws 86 constellations, as Mensa and Microscopium have no lines" do
    lines = Skymap::Catalog::ConstellationLines.new

    constellations = lines.map(&:constellation).uniq

    expect(constellations.size).to eq(86)
    expect(constellations).not_to include("Men", "Mic")
  end

  it "gives each line one of the weights of the IAU charts" do
    lines = Skymap::Catalog::ConstellationLines.new

    weights = lines.map(&:weight).uniq

    expect(weights).to contain_exactly(:bold, :normal, :thin)
  end
end
