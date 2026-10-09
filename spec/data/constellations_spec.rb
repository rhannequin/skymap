# frozen_string_literal: true

RSpec.describe "data/constellations/iau/lines.csv" do
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

RSpec.describe "data/constellations/iau/boundaries.csv" do
  it "borders the 88 IAU constellations" do
    boundaries = Skymap::Catalog::ConstellationBoundaries.new
    lines = Skymap::Catalog::ConstellationLines.new

    constellations = boundaries.flat_map(&:constellations).uniq

    expect(constellations.size).to eq(88)
    expect(constellations).to include(*lines.map(&:constellation))
  end

  it "has points less than 1.1 degrees apart along each border" do
    boundaries = Skymap::Catalog::ConstellationBoundaries.new

    gaps = boundaries.flat_map do |boundary|
      boundary.points.each_cons(2).map do |from, to|
        delta_ra = (to.right_ascension.degrees - from.right_ascension.degrees +
          180) % 360 - 180
        delta_dec = to.declination.degrees - from.declination.degrees
        Math.hypot(delta_ra * from.declination.cos, delta_dec)
      end
    end

    expect(gaps.max).to be < 1.1
  end
end
